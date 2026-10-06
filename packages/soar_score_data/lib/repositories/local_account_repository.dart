import 'package:drift/drift.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../database.dart';

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
}
