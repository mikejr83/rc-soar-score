import 'package:drift/drift.dart' show Variable;
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../database.dart';
import '../schema/table_group.dart';
import '../schema/tables/conflict_records_table.dart';
import 'assignment_markers.dart';
import 'entity_stores.dart';
import 'sql_placeholders.dart';
import 'table_mapper.dart';

/// The server-side sync acceptor's storage over a Drift database.
///
/// Backend only: on an installation's database every call throws a
/// [core.BackendOnlyError], like the other repositories of backend tables.
class DriftSyncAcceptorStore implements core.SyncAcceptorStore {
  DriftSyncAcceptorStore(this._db, this._stores);

  final SoarScoreDatabase _db;
  final EntityStores _stores;

  @override
  Future<T> transaction<T>(
    Future<T> Function(core.SyncAcceptorTransaction tx) body,
  ) async {
    if (!_db.profile.groups.contains(TableGroup.backendOnly)) {
      throw core.BackendOnlyError('SyncAcceptor');
    }
    final tx = _DriftSyncAcceptorTransaction(_db, _stores);
    try {
      return await _db.transaction(() => body(tx));
    } on Object catch (error) {
      throw _asConstraintError(error) ?? error;
    }
  }
}

/// [error] as a [core.SyncConstraintError] when it is a broken unique or
/// foreign-key rule on either backend, else null.
core.SyncConstraintError? _asConstraintError(Object error) {
  if (error is core.SyncConstraintError) return error;
  final text = '$error'.toLowerCase();
  if (text.contains('unique constraint') ||
      text.contains('duplicate key') ||
      text.contains('23505')) {
    return core.SyncConstraintError(core.SyncConstraintKind.unique, '$error');
  }
  if (text.contains('foreign key') || text.contains('23503')) {
    return core.SyncConstraintError(
      core.SyncConstraintKind.foreignKey,
      '$error',
    );
  }
  return null;
}

class _DriftSyncAcceptorTransaction implements core.SyncAcceptorTransaction {
  _DriftSyncAcceptorTransaction(this._db, this._stores)
    : _mutations = TableMapper(
        _db,
        _db.mutationRecords,
        jsonColumns: {'payload'},
      ),
      _conflicts = TableMapper(
        _db,
        _db.conflictRecords,
        jsonColumns: conflictRecordsJsonColumns,
      ),
      _tombstones = TableMapper(_db, _db.tombstones),
      _cursors = TableMapper(_db, _db.syncCursors);

  final SoarScoreDatabase _db;
  final EntityStores _stores;
  final TableMapper _mutations;
  final TableMapper _conflicts;
  final TableMapper _tombstones;
  final TableMapper _cursors;

  // Installations and activations --------------------------------------

  @override
  Future<core.Installation?> findInstallation(core.Id id) async {
    final json = await _stores.of('Installation').findJson(id);
    return json == null ? null : core.Installation.fromJson(json);
  }

  @override
  Future<List<core.Installation>> listInstallations(
    core.Id ownerAccountId,
  ) async => [
    for (final json
        in await _stores
            .of('Installation')
            .whereIdJson('owner_account_id', ownerAccountId))
      core.Installation.fromJson(json),
  ]..sort((a, b) => a.id.value.compareTo(b.id.value));

  @override
  Future<core.Installation> saveInstallation(
    core.Installation installation,
  ) async {
    await _stores.of('Installation').upsertJson(installation.toJson());
    return installation;
  }

  @override
  Future<List<core.InstallationActivation>> listActivations(
    core.Id contestId,
  ) async => [
    for (final json
        in await _stores
            .of('InstallationActivation')
            .whereIdJson('contest_id', contestId))
      core.InstallationActivation.fromJson(json),
  ]..sort((a, b) => a.id.value.compareTo(b.id.value));

  @override
  Future<core.InstallationActivation> saveActivation(
    core.InstallationActivation activation,
  ) async {
    await _stores.of('InstallationActivation').upsertJson(activation.toJson());
    return activation;
  }

  @override
  Future<core.SyncCursor?> findCursor(
    core.Id installationId,
    core.SyncScopeKey scope,
  ) async {
    final (column, id) = _scopeColumn(scope);
    final rows = await _cursors.where('installation_id = ? AND $column = ?', [
      Variable<String>(installationId.value),
      Variable<String>(id),
    ]);
    return rows.isEmpty ? null : core.SyncCursor.fromJson(rows.single);
  }

  @override
  Future<core.SyncCursor> saveCursor(core.SyncCursor cursor) async {
    await _cursors.upsert(cursor.toJson());
    return cursor;
  }

  // Entities -----------------------------------------------------------

  @override
  Future<Map<String, Object?>?> findEntity(String entityType, core.Id id) =>
      _stores.of(entityType).findJson(id);

  @override
  Future<List<Map<String, Object?>>> findEntitiesWhere(
    String entityType,
    String field,
    core.Id value,
  ) => _stores.of(entityType).whereIdJson(field, value);

  @override
  Future<void> writeEntity(String entityType, Map<String, Object?> json) async {
    final store = _stores.of(entityType);
    final Object entity;
    final results = <Object>[];
    try {
      entity = store.decode(json);
      if (entityType == 'LandingTable') {
        final entries = _stores.of('LandingResult');
        for (final entry in json['results'] as List<Object?>? ?? const []) {
          results.add(entries.decode(entry! as Map<String, Object?>));
        }
      }
    } on Object catch (error) {
      throw core.SyncPayloadError('The $entityType is not valid: $error');
    }
    await store.upsertJson(store.encode(entity));
    final entries = _stores.of('LandingResult');
    for (final result in results) {
      await entries.upsertJson(entries.encode(result));
    }
  }

  @override
  Future<void> removeEntity(String entityType, core.Id id) async {
    if (entityType == 'LandingTable') {
      await _stores.of('LandingResult').removeWhereId('landing_table_id', id);
    }
    // The server keeps derived results too; they are recomputed, so they go
    // with the rows they were calculated from.
    if (entityType == 'ScorePlaceholder') {
      await _stores
          .of('FlightResult')
          .removeWhereId('score_placeholder_id', id);
    }
    if (entityType == 'ContestParticipation') {
      await _stores
          .of('FlightResult')
          .removeWhereId('contest_participation_id', id);
      await _stores
          .of('ParticipationStanding')
          .removeWhereId('contest_participation_id', id);
    }
    await _stores.of(entityType).remove(id);
    if (entityType == 'MatrixAssignment') {
      await clearSupersededMarkers(_db, id);
    }
  }

  @override
  Future<void> markSuperseded(core.Id sourceId, core.Id movedId) async {
    final marked = await _db.customUpdate(
      portableSql(
        _db,
        'UPDATE matrix_assignments SET superseded_by_assignment_id = ? '
        'WHERE id = ? AND superseded_by_assignment_id IS NULL',
      ),
      variables: [
        Variable<String>(movedId.value),
        Variable<String>(sourceId.value),
      ],
      updates: {_db.matrixAssignments},
    );
    if (marked != 1) {
      throw core.SyncConstraintError(
        core.SyncConstraintKind.unique,
        'the assignment ${sourceId.value} was already moved',
      );
    }
  }

  // The log ------------------------------------------------------------

  @override
  Future<core.MutationRecord?> findMutation(
    core.SyncScopeKey scope,
    String clientMutationId,
  ) async {
    final (column, id) = _scopeColumn(scope);
    final rows = await _mutations.where(
      '$column = ? AND client_mutation_id = ?',
      [Variable<String>(id), Variable<String>(clientMutationId)],
    );
    return rows.isEmpty ? null : core.MutationRecord.fromJson(rows.single);
  }

  @override
  Future<List<core.MutationRecord>> acceptedMutationsFor(
    core.SyncScopeKey scope,
    String entityType,
    core.Id entityId,
  ) async {
    final (column, id) = _scopeColumn(scope);
    final rows = await _mutations.where(
      "$column = ? AND outcome = 'Accepted' AND entity_type = ? "
      'AND entity_id = ?',
      [
        Variable<String>(id),
        Variable<String>(entityType),
        Variable<String>(entityId.value),
      ],
      orderBy: 'sequence',
    );
    return [for (final row in rows) core.MutationRecord.fromJson(row)];
  }

  @override
  Future<int> highestSequence(core.SyncScopeKey scope) async {
    final (column, id) = _scopeColumn(scope);
    final row = await _db
        .customSelect(
          portableSql(
            _db,
            'SELECT MAX(sequence) AS highest FROM mutation_records '
            'WHERE $column = ?',
          ),
          variables: [Variable<String>(id)],
          readsFrom: {_db.mutationRecords},
        )
        .getSingle();
    return row.read<int?>('highest') ?? 0;
  }

  @override
  Future<void> recordMutation(core.MutationRecord record) =>
      _mutations.upsert(record.toJson());

  @override
  Future<List<core.MutationRecord>> acceptedAfter(
    core.SyncScopeKey scope,
    int afterSequence, {
    required int limit,
  }) async {
    final (column, id) = _scopeColumn(scope);
    final rows = await _mutations.where(
      "$column = ? AND outcome = 'Accepted' AND sequence > ?",
      [Variable<String>(id), Variable<int>(afterSequence)],
      orderBy: 'sequence',
      limit: limit,
    );
    return [for (final row in rows) core.MutationRecord.fromJson(row)];
  }

  // Tombstones, conflicts and audit ------------------------------------

  @override
  Future<core.Tombstone?> findTombstone(
    String entityType,
    core.Id entityId,
  ) async {
    final rows = await _tombstones.where('entity_type = ? AND entity_id = ?', [
      Variable<String>(entityType),
      Variable<String>(entityId.value),
    ]);
    return rows.isEmpty ? null : core.Tombstone.fromJson(rows.single);
  }

  @override
  Future<void> saveTombstone(core.Tombstone tombstone) =>
      _tombstones.upsert(tombstone.toJson());

  @override
  Future<core.ConflictRecord?> findConflict(core.Id id) async {
    final json = await _conflicts.find(id);
    return json == null ? null : core.ConflictRecord.fromJson(json);
  }

  @override
  Future<void> saveConflict(core.ConflictRecord conflict) =>
      _conflicts.upsert(conflict.toJson());

  @override
  Future<List<core.ConflictRecord>> conflictsNeedingAction(
    core.SyncScopeKey scope,
  ) async {
    final (column, id) = _scopeColumn(scope);
    final rows = await _conflicts.where(
      "requires_action = ? AND resolution = 'Pending' AND $column = ?",
      [Variable<bool>(true), Variable<String>(id)],
      orderBy: 'created_at, id',
    );
    return [for (final row in rows) core.ConflictRecord.fromJson(row)];
  }

  @override
  Future<void> appendAudit(core.AuditEvent event) =>
      _stores.of('AuditEvent').upsertJson(event.toJson());

  (String, String) _scopeColumn(core.SyncScopeKey scope) => switch (scope) {
    core.ContestScopeKey(:final contestId) => ('contest_id', contestId.value),
    core.DirectorScopeKey(:final ownerAccountId) => (
      'owner_account_id',
      ownerAccountId.value,
    ),
    core.SystemScopeKey() => throw ArgumentError.value(
      scope,
      'scope',
      'system data has no sync log',
    ),
  };
}
