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

  /// The rows matching [whereSql], in [orderBy] order.
  Future<List<Map<String, Object?>>> where(
    String whereSql,
    List<Variable> variables, {
    String? orderBy,
  }) async {
    final order = orderBy == null ? '' : ' ORDER BY $orderBy';
    final rows = await _db
        .customSelect(
          portableSql(_db, 'SELECT * FROM $_name WHERE $whereSql$order'),
          variables: variables,
          readsFrom: {_table},
        )
        .get();
    return [for (final row in rows) _fromRow(row.data)];
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

  /// Removes the row with [id]; returns whether one existed.
  Future<bool> remove(core.Id id) async {
    final count = await _db.customUpdate(
      portableSql(_db, 'DELETE FROM $_name WHERE id = ?'),
      variables: [Variable<String>(id.value)],
      updates: {_table},
    );
    return count > 0;
  }

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
