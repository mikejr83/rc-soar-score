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
      final companion = ContestsCompanion(
        id: Value(contest.id.value),
        name: Value(contest.name),
        startedAt: Value(contest.startedAt.toUtc().toIso8601String()),
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

  static core.Contest _toDomain(ContestData row) => core.Contest(
    id: core.Id.parse(row.id),
    name: row.name,
    startedAt: DateTime.parse(row.startedAt).toUtc(),
  );
}
