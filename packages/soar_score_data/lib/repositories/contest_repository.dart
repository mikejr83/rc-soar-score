import 'package:drift/drift.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../database.dart';

/// Backend-agnostic contest repository backed by [SoarScoreDatabase].
///
/// Works identically with SQLite or PostgreSQL — the executor is chosen at
/// `ContestDatabase` construction, not repository construction. This replaces
/// `ContestSqliteRepository` and `ContestPostgresRepository` with a single
/// implementation.
class ContestRepository implements core.ContestRepository {
  ContestRepository(this._db);

  final SoarScoreDatabase _db;

  @override
  Future<core.Contest?> findById(core.Id id) async {
    final row = await (_db.select(
      _db.contests,
    )..where((c) => c.id.equals(id.value))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<core.Contest>> getAll() async {
    final rows = await _db.select(_db.contests).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<core.Contest> save(core.Contest contest) {
    return _db.transaction(() async {
      final json = contest.toJson();
      final companion = ContestsCompanion(
        id: Value(contest.id.value),
        name: Value(contest.name),
        startDateTime: Value(json['start_date_time']! as String),
        endDateTime: Value(json['end_date_time']! as String),
        timezone: Value(contest.timezone),
        host: Value(contest.host),
        city: Value(contest.city),
        state: Value(contest.state),
        country: Value(contest.country),
        ownerAccountId: Value(contest.ownerAccountId?.value),
        lifecycleState: Value(json['lifecycle_state']! as String),
        scoringAccess: Value(json['scoring_access']! as String),
        adminLock: Value(json['admin_lock']! as String),
        resultsHiddenThroughRound: Value(contest.resultsHiddenThroughRound),
        resultsHiddenAt: Value(json['results_hidden_at'] as String?),
        localArchive: Value(contest.localArchive),
        createdAt: Value(json['created_at']! as String),
        updatedAt: Value(json['updated_at']! as String),
        revision: Value(contest.revision),
      );
      final updated = await (_db.update(
        _db.contests,
      )..where((c) => c.id.equals(contest.id.value))).write(companion);
      if (updated == 0) {
        await _db.into(_db.contests).insert(companion);
      }
      return contest;
    });
  }

  @override
  Future<bool> delete(core.Id id) async {
    final deleted = await (_db.delete(
      _db.contests,
    )..where((c) => c.id.equals(id.value))).go();
    return deleted > 0;
  }

  @override
  Future<void> close() => _db.close();

  static core.Contest _toDomain(ContestData row) => core.Contest.fromJson({
    'id': row.id,
    'name': row.name,
    'start_date_time': row.startDateTime,
    'end_date_time': row.endDateTime,
    'timezone': row.timezone,
    'host': row.host,
    'city': row.city,
    'state': row.state,
    'country': row.country,
    'owner_account_id': row.ownerAccountId,
    'lifecycle_state': row.lifecycleState,
    'scoring_access': row.scoringAccess,
    'admin_lock': row.adminLock,
    'results_hidden_through_round': row.resultsHiddenThroughRound,
    'results_hidden_at': row.resultsHiddenAt,
    'local_archive': row.localArchive,
    'created_at': row.createdAt,
    'updated_at': row.updatedAt,
    'revision': row.revision,
  });
}
