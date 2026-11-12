import 'package:drift/drift.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../database.dart';
import '../schema/tables/conflict_records_table.dart';
import 'table_mapper.dart';

/// The client's synchronization state: its outbox, conflicts and position.
class DriftSyncStore implements core.SyncStore {
  DriftSyncStore(this._db)
    : _mutations = TableMapper(
        _db,
        _db.mutationRecords,
        jsonColumns: {'payload'},
      ),
      _conflicts = TableMapper(
        _db,
        _db.conflictRecords,
        jsonColumns: conflictRecordsJsonColumns,
      );

  final SoarScoreDatabase _db;
  final TableMapper _mutations;
  final TableMapper _conflicts;

  @override
  Future<List<core.MutationRecord>> pendingMutations(
    core.SyncScopeKey scope,
  ) async {
    if (scope is core.SystemScopeKey) return const [];
    final (column, id) = _scopeColumn(scope);
    final rows = await _mutations.where("outcome = 'Pending' AND $column = ?", [
      Variable<String>(id),
    ], orderBy: 'client_time, id');
    return [for (final row in rows) core.MutationRecord.fromJson(row)];
  }

  @override
  Future<List<core.MutationRecord>> rejectedMutations(
    core.SyncScopeKey scope,
  ) async {
    if (scope is core.SystemScopeKey) return const [];
    final (column, id) = _scopeColumn(scope);
    final rows = await _mutations.where(
      "outcome = 'Rejected' AND $column = ?",
      [Variable<String>(id)],
      orderBy: 'client_time, id',
    );
    return [for (final row in rows) core.MutationRecord.fromJson(row)];
  }

  @override
  Future<Set<core.Id>> refusedMutationIds(core.SyncScopeKey scope) async {
    if (scope is core.SystemScopeKey) return const {};
    final (column, id) = _scopeColumn(scope);
    final rows = await _mutations.where(
      "outcome IN ('Rejected', 'Conflict') AND $column = ?",
      [Variable<String>(id)],
      orderBy: 'client_time, id',
    );
    return {for (final row in rows) core.Id.parse(row['id']! as String)};
  }

  @override
  Future<void> recordOutcome({
    required core.Id mutationId,
    required core.MutationOutcome outcome,
    int? sequence,
    DateTime? serverAcceptanceTime,
    DateTime? serverRejectionTime,
    String? reasonCode,
    String? errorMessage,
  }) => _db.transaction(() async {
    final row = await _mutations.find(mutationId);
    if (row == null) {
      throw ArgumentError.value(
        mutationId,
        'mutationId',
        'is not in the outbox',
      );
    }
    if (outcome == core.MutationOutcome.accepted && sequence == null) {
      throw ArgumentError.notNull('sequence');
    }
    final current = core.MutationRecord.fromJson(row);
    final updated = core.MutationRecord(
      id: current.id,
      contestId: current.contestId,
      ownerAccountId: current.ownerAccountId,
      sequence: sequence,
      entityType: current.entityType,
      entityId: current.entityId,
      baseRevision: current.baseRevision,
      clientMutationId: current.clientMutationId,
      actorId: current.actorId,
      authority: current.authority,
      sourceInstallationId: current.sourceInstallationId,
      sourceDevice: current.sourceDevice,
      clientTime: current.clientTime,
      serverAcceptanceTime: serverAcceptanceTime,
      serverRejectionTime: serverRejectionTime,
      payload: current.payload,
      outcome: outcome,
      reasonCode: reasonCode,
      errorMessage: errorMessage,
      dependsOnMutationId: current.dependsOnMutationId,
    );
    if (current.outcome != core.MutationOutcome.pending) {
      if (current == updated) return;
      throw StateError(
        'mutation ${mutationId.value} already has outcome '
        '${current.outcome.name}',
      );
    }
    await _mutations.upsert(updated.toJson());
  });

  @override
  Future<int> readCursor(core.SyncScopeKey scope) async =>
      (await _position(scope))?.lastSyncedSequence ?? 0;

  @override
  Future<void> writeCursor(
    core.SyncScopeKey scope,
    int lastSyncedSequence, {
    DateTime? syncedAt,
  }) => _db.transaction(() async {
    final current = await _position(scope);
    if (current != null && lastSyncedSequence < current.lastSyncedSequence) {
      throw ArgumentError.value(
        lastSyncedSequence,
        'lastSyncedSequence',
        'is behind the stored position ${current.lastSyncedSequence}',
      );
    }
    final (kind, id) = _scopeKey(scope);
    await _db
        .into(_db.localSyncPositions)
        .insertOnConflictUpdate(
          LocalSyncPositionsCompanion.insert(
            scopeKind: kind,
            scopeId: id,
            lastSyncedSequence: Value(lastSyncedSequence),
            lastSyncedAt: Value(syncedAt?.toUtc().toIso8601String()),
          ),
        );
  });

  @override
  Future<List<core.ConflictRecord>> conflictsNeedingAction(
    core.SyncScopeKey scope,
  ) async {
    if (scope is core.SystemScopeKey) return const [];
    final (column, id) = _scopeColumn(scope);
    final rows = await _conflicts.where(
      "requires_action = ? AND resolution = 'Pending' AND $column = ?",
      [Variable<bool>(true), Variable<String>(id)],
      orderBy: 'created_at, id',
    );
    return [for (final row in rows) core.ConflictRecord.fromJson(row)];
  }

  @override
  Future<core.SyncStatus> status(core.SyncScopeKey scope) async {
    final position = await _position(scope);
    return core.SyncStatus(
      pendingMutations: (await pendingMutations(scope)).length,
      rejectedMutations: (await rejectedMutations(scope)).length,
      conflictsNeedingAction: (await conflictsNeedingAction(scope)).length,
      lastSyncedSequence: position?.lastSyncedSequence ?? 0,
      lastSyncedAt: position?.lastSyncedAt == null
          ? null
          : DateTime.parse(position!.lastSyncedAt!).toUtc(),
    );
  }

  Future<LocalSyncPositionData?> _position(core.SyncScopeKey scope) {
    final (kind, id) = _scopeKey(scope);
    return (_db.select(_db.localSyncPositions)
          ..where((p) => p.scopeKind.equals(kind) & p.scopeId.equals(id)))
        .getSingleOrNull();
  }

  (String, String) _scopeKey(core.SyncScopeKey scope) => switch (scope) {
    core.ContestScopeKey(:final contestId) => ('Contest', contestId.value),
    core.DirectorScopeKey(:final ownerAccountId) => (
      'Director',
      ownerAccountId.value,
    ),
    core.SystemScopeKey() => ('System', 'system'),
  };

  (String, String) _scopeColumn(core.SyncScopeKey scope) => switch (scope) {
    core.ContestScopeKey(:final contestId) => ('contest_id', contestId.value),
    core.DirectorScopeKey(:final ownerAccountId) => (
      'owner_account_id',
      ownerAccountId.value,
    ),
    core.SystemScopeKey() => throw ArgumentError.value(
      scope,
      'scope',
      'system data has no mutations or conflicts',
    ),
  };
}
