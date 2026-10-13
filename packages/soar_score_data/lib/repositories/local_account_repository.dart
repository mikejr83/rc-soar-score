import 'package:drift/drift.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../database.dart';
import '../schema/local_account_references.dart';
import '../sync/sql_placeholders.dart';

/// The Local account id of an installation, kept in `local_account`.
///
/// Only a native database has the table; the server profile omits it.
class LocalAccountRepository implements core.LocalAccountRepository {
  LocalAccountRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SoarScoreDatabase _db;
  final DateTime Function() _clock;

  @override
  Future<core.Id?> find() async {
    final row = await _db.select(_db.localAccount).getSingleOrNull();
    return row == null ? null : core.Id.parse(row.accountId);
  }

  @override
  Future<core.Id> ensure() => _db.transaction(() async {
    final existing = await find();
    if (existing != null) return existing;
    final id = core.Id.create();
    await _db
        .into(_db.localAccount)
        .insert(
          LocalAccountCompanion.insert(
            slot: const Value(1),
            accountId: id.value,
            createdAt: _clock().toUtc().toIso8601String(),
          ),
        );
    return id;
  });

  @override
  Future<void> reassignTo(core.Id accountId) => _db.transaction(() async {
    final local = await find();
    if (local == null) {
      throw StateError('the Local account has not been created yet');
    }
    if (local == accountId) {
      throw ArgumentError.value(
        accountId,
        'accountId',
        'is the Local account itself',
      );
    }
    for (final MapEntry(key: table, value: columns)
        in localAccountReferences.entries) {
      for (final column in columns) {
        await _update('UPDATE $table SET $column = ? WHERE $column = ?', [
          accountId.value,
          local.value,
        ], table);
      }
    }
    for (final MapEntry(key: table, value: columns)
        in localAccountJsonReferences.entries) {
      for (final column in columns) {
        await _update(
          "UPDATE $table SET $column = REPLACE($column, ?, ?) "
          "WHERE $column LIKE ?",
          [local.value, accountId.value, '%${local.value}%'],
          table,
        );
      }
    }
    // A director scope is named by the account that owns it.
    await _update(
      "UPDATE local_sync_positions SET scope_id = ? "
          "WHERE scope_kind = 'Director' AND scope_id = ?",
      [accountId.value, local.value],
      'local_sync_positions',
    );
  });

  Future<void> _update(String sql, List<String> args, String table) =>
      _db.customUpdate(
        portableSql(_db, sql),
        variables: [for (final arg in args) Variable<String>(arg)],
        updates: {_db.allTables.firstWhere((t) => t.actualTableName == table)},
        updateKind: UpdateKind.update,
      );
}
