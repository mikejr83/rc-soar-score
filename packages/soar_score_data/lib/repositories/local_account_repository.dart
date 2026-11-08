import 'dart:convert';

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
  Future<core.Id?> linkedAccount() async {
    final value =
        (await _db.select(_db.localAccount).getSingleOrNull())?.linkedAccountId;
    return value == null ? null : core.Id.parse(value);
  }

  @override
  Future<core.AccountPreferences> preferences() async {
    final row = await _db.select(_db.localAccount).getSingleOrNull();
    return core.AccountPreferences(
      preferredTimeZone: row?.preferredTimeZone,
      preferredLocale: row?.preferredLocale,
    );
  }

  @override
  Future<void> savePreferences(core.AccountPreferences preferences) async {
    final updated =
        await (_db.update(
          _db.localAccount,
        )..where((t) => t.slot.equals(1))).write(
          LocalAccountCompanion(
            preferredTimeZone: Value(preferences.preferredTimeZone),
            preferredLocale: Value(preferences.preferredLocale),
          ),
        );
    if (updated == 0) {
      throw StateError('the Local account has not been created yet');
    }
  }

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
    await (_db.update(_db.localAccount)..where((t) => t.slot.equals(1))).write(
      LocalAccountCompanion(linkedAccountId: Value(accountId.value)),
    );
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
        await _rewriteJson(table, column, local, accountId);
      }
    }
    // A director scope is named by the account that owns it. Its position
    // moves to the account unless the account already has one, which stands:
    // the Local scope was never synced, so its position says nothing.
    await _update(
      "UPDATE local_sync_positions SET scope_id = ? "
          "WHERE scope_kind = 'Director' AND scope_id = ? AND NOT EXISTS ("
          "SELECT 1 FROM local_sync_positions p WHERE p.scope_kind = 'Director' "
          "AND p.scope_id = ?)",
      [accountId.value, local.value, accountId.value],
      'local_sync_positions',
    );
    await _update(
      "DELETE FROM local_sync_positions "
          "WHERE scope_kind = 'Director' AND scope_id = ?",
      [local.value],
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

  /// Rewrites the account fields of the JSON in [table].[column], leaving any
  /// other text that happens to contain the id, such as a name typed by a
  /// user, as it was.
  Future<void> _rewriteJson(
    String table,
    String column,
    core.Id local,
    core.Id accountId,
  ) async {
    final rows = await _db
        .customSelect(
          portableSql(
            _db,
            'SELECT id, $column AS json FROM $table WHERE $column LIKE ?',
          ),
          variables: [Variable<String>('%${local.value}%')],
        )
        .get();
    for (final row in rows) {
      final decoded = jsonDecode(row.read<String>('json'));
      final rewritten = _rewriteAccounts(decoded, local.value, accountId.value);
      await _update('UPDATE $table SET $column = ? WHERE id = ?', [
        jsonEncode(rewritten),
        row.read<String>('id'),
      ], table);
    }
  }

  static Object? _rewriteAccounts(Object? node, String from, String to) =>
      switch (node) {
        Map() => {
          for (final MapEntry(:key, :value) in node.entries)
            key: _accountKeys.contains(key) && value == from
                ? to
                : _rewriteAccounts(value, from, to),
        },
        List() => [for (final item in node) _rewriteAccounts(item, from, to)],
        _ => node,
      };

  /// The JSON keys of the columns that hold an account id.
  static final _accountKeys = {
    for (final columns in localAccountReferences.values) ...columns,
  };
}
