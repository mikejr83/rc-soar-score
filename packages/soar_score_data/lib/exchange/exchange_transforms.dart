import '../schema/local_account_references.dart';
import 'exchange_file.dart';

/// Rows by table, as the sync stores' JSON.
typedef ExchangeTables = Map<String, List<Map<String, Object?>>>;

/// Columns whose text may hold contact details or text typed by people that
/// embeds them. Dropped (set to null) from a redacted export.
const _freeTextColumns = <String, List<String>>{
  'audit_events': ['reason'],
  'mutation_records': ['error_message'],
  'conflict_records': ['reason'],
};

/// The JSON keys that hold contact details wherever they appear.
const _contactKeys = {'email'};

/// Whether [column] names the owner of a row. Owner columns always end up
/// with the importing owner, whoever they named in the file.
bool _isOwnerColumn(String column) => column == 'owner_account_id';

/// [tables] without contact details.
///
/// Every key named `email` is emptied wherever it sits, including inside
/// stored mutations and conflict payloads (which are walked, not searched as
/// text), and the free text that may embed contact details is dropped. Ids,
/// scores, revisions and timestamps never change, so scoring problems still
/// reproduce. Names, clubs, national numbers and places stay: they are
/// scoring-relevant or public roster data.
ExchangeTables redactTables(ExchangeTables tables) => {
  for (final MapEntry(key: table, value: rows) in tables.entries)
    table: [
      for (final row in rows)
        {
          for (final MapEntry(key: column, value: value) in row.entries)
            column:
                (_freeTextColumns[table]?.contains(column) ?? false) ||
                    _contactKeys.contains(column.toLowerCase())
                ? null
                : _redactNode(value),
        },
    ],
};

Object? _redactNode(Object? node) => switch (node) {
  Map() => {
    for (final MapEntry(:key, :value) in node.entries)
      key: _contactKeys.contains('$key'.toLowerCase())
          ? null
          : _redactNode(value),
  },
  List() => [for (final item in node) _redactNode(item)],
  _ => node,
};

/// Redacts the diagnostics block the same way as the rows.
Map<String, Object?> redactDiagnostics(Map<String, Object?> diagnostics) =>
    (_redactNode(diagnostics) as Map).cast<String, Object?>();

/// A copy of [tables] with every account reference of the people in [from]
/// pointing at [to] instead, and every owner column set to [to].
///
/// Only the records read from a file go through this, in memory, before
/// anything is inserted; the claim of a Local account (which rewrites a whole
/// database) is a different operation and does not use it. Columns are those
/// of [localAccountReferences]; JSON inside stored mutations and conflicts is
/// walked so text that merely contains an id, such as a name, stays as it was.
/// Client mutation ids are never touched.
ExchangeTables rewriteAccountReferences(
  ExchangeTables tables, {
  required Set<String> from,
  required String to,
}) {
  final jsonColumns = {
    for (final MapEntry(:key, :value) in localAccountJsonReferences.entries)
      key: value.toSet(),
  };
  return {
    for (final MapEntry(key: table, value: rows) in tables.entries)
      table: [
        for (final row in rows)
          {
            for (final MapEntry(key: column, value: value) in row.entries)
              column: _rewriteColumn(
                table,
                column,
                value,
                from,
                to,
                jsonColumns,
              ),
          },
      ],
  };
}

Object? _rewriteColumn(
  String table,
  String column,
  Object? value,
  Set<String> from,
  String to,
  Map<String, Set<String>> jsonColumns,
) {
  if (jsonColumns[table]?.contains(column) ?? false) {
    return _rewriteNode(value, from, to);
  }
  final isReference = localAccountReferences[table]?.contains(column) ?? false;
  if (!isReference) return value;
  if (_isOwnerColumn(column)) {
    // Every owned row ends up with the importing owner. A contest with no
    // owner (made before there was a Local account) is given one; the other
    // tables use a missing owner for contest-scope rows and system rows.
    return value == null && table != 'contests' ? null : to;
  }
  return value is String && from.contains(value) ? to : value;
}

Object? _rewriteNode(Object? node, Set<String> from, String to) =>
    switch (node) {
      Map() => {
        for (final MapEntry(:key, :value) in node.entries)
          key: _accountKeys.contains(key) && value is String
              ? (_isOwnerColumn('$key') || from.contains(value) ? to : value)
              : _rewriteNode(value, from, to),
      },
      List() => [for (final item in node) _rewriteNode(item, from, to)],
      _ => node,
    };

final _accountKeys = {
  for (final columns in localAccountReferences.values) ...columns,
};

/// The ids of [file]'s rows of [table] as a set.
Set<String> idsOf(ExchangeFile file, String table) => {
  for (final row in file.rows(table))
    if (row['id'] case final String id) id,
};
