import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import 'sql_placeholders.dart';

/// Reads and writes the rows of one table as the JSON the model classes use.
///
/// Every column is named like its JSON key (snake_case), so one mapper serves
/// every entity table and a saved entity reads back exactly as its model wrote
/// it. Booleans, JSON-shaped text and numbers are converted by column.
class TableMapper {
  TableMapper(this._db, this._table, {Set<String> jsonColumns = const {}})
    : _jsonColumns = jsonColumns;

  final GeneratedDatabase _db;
  final TableInfo<Table, Object?> _table;

  /// Columns that hold a JSON object or array as text.
  final Set<String> _jsonColumns;

  String get _name => _table.actualTableName;

  /// The row with [id], or null.
  Future<Map<String, Object?>?> find(core.Id id) async {
    final rows = await where('id = ?', [Variable<String>(id.value)]);
    return rows.isEmpty ? null : rows.single;
  }

  /// The rows matching [whereSql], in [orderBy] order, at most [limit].
  Future<List<Map<String, Object?>>> where(
    String whereSql,
    List<Variable> variables, {
    String? orderBy,
    int? limit,
    int? offset,
    bool forUpdate = false,
  }) async {
    final order = orderBy == null ? '' : ' ORDER BY $orderBy';
    final cap =
        (limit == null ? '' : ' LIMIT $limit') +
        (offset == null ? '' : ' OFFSET $offset');
    // PostgreSQL locks the rows until the transaction ends; SQLite has one
    // writer, which the transaction already holds.
    final lock = forUpdate && _db.executor.dialect == SqlDialect.postgres
        ? ' FOR UPDATE'
        : '';
    final rows = await _db
        .customSelect(
          portableSql(
            _db,
            'SELECT * FROM $_name WHERE $whereSql$order$cap$lock',
          ),
          variables: variables,
          readsFrom: {_table},
        )
        .get();
    return [for (final row in rows) _fromRow(row.data)];
  }

  /// How many rows match [whereSql].
  Future<int> count(String whereSql, List<Variable> variables) async {
    final rows = await _db
        .customSelect(
          portableSql(_db, 'SELECT COUNT(*) AS n FROM $_name WHERE $whereSql'),
          variables: variables,
          readsFrom: {_table},
        )
        .get();
    return (rows.single.data['n']! as num).toInt();
  }

  /// Every row, in [orderBy] order.
  Future<List<Map<String, Object?>>> all({String? orderBy}) async {
    final order = orderBy == null ? '' : ' ORDER BY $orderBy';
    final rows = await _db
        .customSelect('SELECT * FROM $_name$order', readsFrom: {_table})
        .get();
    return [for (final row in rows) _fromRow(row.data)];
  }

  /// Inserts [json], or replaces the row with the same key.
  ///
  /// Plain SQL with `ON CONFLICT ... DO UPDATE`, which SQLite and PostgreSQL
  /// both accept, so the write is the same on either backend.
  Future<void> upsert(Map<String, Object?> json) async {
    final columns = [for (final c in _table.$columns) c.$name];
    final keys = [for (final c in _table.$primaryKey) c.$name];
    final updates = [
      for (final name in columns)
        if (!keys.contains(name)) '"$name" = excluded."$name"',
    ];
    final conflict = updates.isEmpty
        ? 'DO NOTHING'
        : 'DO UPDATE SET ${updates.join(', ')}';
    await _db.customInsert(
      portableSql(
        _db,
        'INSERT INTO $_name (${columns.map((c) => '"$c"').join(', ')}) '
        'VALUES (${List.filled(columns.length, '?').join(', ')}) '
        'ON CONFLICT (${keys.map((k) => '"$k"').join(', ')}) $conflict',
      ),
      variables: _toVariables(json, columns),
      updates: {_table},
    );
  }

  /// Inserts every row of [rows] that is not stored yet, never touching a
  /// stored one, and returns how many were inserted.
  ///
  /// Rows go in multi-row statements (`INSERT ... VALUES (...), (...) ON
  /// CONFLICT DO NOTHING`), as many per statement as the smallest bound
  /// variable limit of the backends allows, so a large install costs a few
  /// statements instead of one per row.
  Future<int> insertMissing(List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) return 0;
    final columns = [for (final c in _table.$columns) c.$name];
    final keys = [for (final c in _table.$primaryKey) c.$name];
    final perStatement = (_maxVariables ~/ columns.length).clamp(1, 1 << 20);
    final tuple = '(${List.filled(columns.length, '?').join(', ')})';
    var inserted = 0;
    for (var start = 0; start < rows.length; start += perStatement) {
      final chunk = rows.skip(start).take(perStatement).toList();
      inserted += await _db.customUpdate(
        portableSql(
          _db,
          'INSERT INTO $_name (${columns.map((c) => '"$c"').join(', ')}) '
          'VALUES ${List.filled(chunk.length, tuple).join(', ')} '
          'ON CONFLICT (${keys.map((k) => '"$k"').join(', ')}) DO NOTHING',
        ),
        variables: [for (final row in chunk) ..._toVariables(row, columns)],
        updates: {_table},
      );
    }
    return inserted;
  }

  /// Below the variable limit of every supported backend (older SQLite: 999).
  static const _maxVariables = 900;

  /// Writes [json] as the next revision of the row stored at
  /// [expectedRevision], or inserts it when [expectedRevision] is null; the
  /// write is refused (returns false) when the stored row is not at that
  /// revision any more, or exists although none was expected.
  ///
  /// The revision is compared by the database in the same statement as the
  /// write, so a writer that did not take the contest gate cannot be
  /// overwritten between a read and this write, and a row deleted in between
  /// is not recreated.
  Future<bool> upsertIfRevision(
    Map<String, Object?> json,
    int? expectedRevision,
  ) async {
    final columns = [for (final c in _table.$columns) c.$name];
    final keys = [for (final c in _table.$primaryKey) c.$name];
    final values = [for (final c in columns.where((c) => !keys.contains(c))) c];
    if (expectedRevision != null && values.isNotEmpty) {
      // An existing row: a plain UPDATE, so a row another connection deleted
      // meanwhile is not brought back at the next revision.
      final changed = await _db.customUpdate(
        portableSql(
          _db,
          'UPDATE $_name SET ${values.map((c) => '"$c" = ?').join(', ')} '
          'WHERE ${keys.map((k) => '"$k" = ?').join(' AND ')} '
          'AND "revision" = ?',
        ),
        variables: [
          ..._toVariables(json, values),
          ..._toVariables(json, keys),
          Variable<int>(expectedRevision),
        ],
        updates: {_table},
      );
      return changed > 0;
    }
    final changed = await _db.customUpdate(
      portableSql(
        _db,
        'INSERT INTO $_name (${columns.map((c) => '"$c"').join(', ')}) '
        'VALUES (${List.filled(columns.length, '?').join(', ')}) '
        'ON CONFLICT (${keys.map((k) => '"$k"').join(', ')}) DO NOTHING',
      ),
      variables: _toVariables(json, columns),
      updates: {_table},
    );
    return changed > 0;
  }

  /// Removes the row with [id]; returns whether one existed.
  Future<bool> remove(core.Id id) async {
    final count = await _db.customUpdate(
      portableSql(_db, 'DELETE FROM $_name WHERE id = ?'),
      variables: [Variable<String>(id.value)],
      updates: {_table},
    );
    return count > 0;
  }

  /// Removes every row whose [column] equals [value]; returns how many.
  ///
  /// [column] is a column name from the schema, never user input.
  Future<int> removeWhere(String column, core.Id value) => _db.customUpdate(
    portableSql(_db, 'DELETE FROM $_name WHERE $column = ?'),
    variables: [Variable<String>(value.value)],
    updates: {_table},
  );

  Map<String, Object?> _fromRow(Map<String, Object?> data) {
    final json = <String, Object?>{};
    for (final column in _table.$columns) {
      final name = column.$name;
      final value = data[name];
      if (value == null) {
        json[name] = null;
      } else if (_jsonColumns.contains(name)) {
        json[name] = jsonDecode(value as String);
      } else if (column.type == DriftSqlType.bool && value is int) {
        json[name] = value != 0;
      } else {
        json[name] = value;
      }
    }
    return json;
  }

  List<Variable> _toVariables(Map<String, Object?> json, List<String> names) {
    final columns = {for (final c in _table.$columns) c.$name: c};
    return [
      for (final name in names)
        switch (json[name]) {
          null => const Variable<Object>(null),
          final value when _jsonColumns.contains(name) => Variable<String>(
            jsonEncode(value),
          ),
          final num value when columns[name]!.type == DriftSqlType.double =>
            Variable<double>(value.toDouble()),
          final value => Variable<Object>(value),
        },
    ];
  }
}
