import 'package:drift/drift.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../postgres/database.dart';

/// PostgreSQL-backed [ContestRepository] implementation for the deployed API
/// server.
///
/// Kept structurally in sync with `ContestSqliteRepository` so the two
/// backends can be wired interchangeably behind the `soar_score_core`
/// contract.
class ContestPostgresRepository implements ContestRepository {
  ContestPostgresRepository(this._database);

  final ContestDatabase _database;

  @override
  Future<Contest?> findById(Id id) async {
    final row = await (_database.select(
      _database.contests,
    )..where((c) => c.id.equals(id.value))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<Contest>> getAll() async {
    final rows = await _database.select(_database.contests).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<Contest> save(Contest contest) {
    return _database.transaction(() async {
      final companion = ContestsCompanion(
        id: Value(contest.id.value),
        name: Value(contest.name),
        startedAt: Value(contest.startedAt.toUtc().toIso8601String()),
      );
      final updated = await (_database.update(
        _database.contests,
      )..where((c) => c.id.equals(contest.id.value))).write(companion);
      if (updated == 0) {
        await _database.into(_database.contests).insert(companion);
      }
      return contest;
    });
  }

  @override
  Future<bool> delete(Id id) async {
    final deleted = await (_database.delete(
      _database.contests,
    )..where((c) => c.id.equals(id.value))).go();
    return deleted > 0;
  }

  @override
  Future<void> close() => _database.close();

  static Contest _toDomain(ContestData row) => Contest(
    id: Id.parse(row.id),
    name: row.name,
    startedAt: DateTime.parse(row.startedAt).toUtc(),
  );
}
