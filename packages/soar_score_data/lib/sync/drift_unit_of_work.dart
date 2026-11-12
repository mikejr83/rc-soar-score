import 'package:drift/drift.dart' show Variable;
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../database.dart';
import '../schema/database_profile.dart';
import 'assignment_markers.dart';
import 'entity_stores.dart';
import 'mutation_payload.dart';
import 'scope_sequence.dart';
import 'sql_placeholders.dart';
import 'table_mapper.dart';

/// The only way this package changes synchronized data.
///
/// One database transaction stores the entity, bumps its revision and writes
/// the `MutationRecord` (and, for a delete, the `Tombstone`). If anything
/// throws, none of it is kept.
class DriftUnitOfWork implements core.UnitOfWork {
  DriftUnitOfWork(
    this._db,
    this._stores, {
    DateTime Function()? clock,
    core.Id Function()? newId,
  }) : _clock = clock ?? (() => DateTime.now().toUtc()),
       _newId = newId ?? core.Id.create,
       _mutations = TableMapper(
         _db,
         _db.mutationRecords,
         jsonColumns: {'payload'},
       ),
       _tombstones = TableMapper(_db, _db.tombstones);

  final SoarScoreDatabase _db;
  final EntityStores _stores;
  final DateTime Function() _clock;
  final core.Id Function() _newId;
  final TableMapper _mutations;
  final TableMapper _tombstones;

  @override
  Future<T> run<T>(Future<T> Function(core.WriteContext context) body) async {
    final context = _Context(this);
    final result = await _db.transaction(() => body(context));
    // Told only after the transaction committed, so a listener that starts a
    // sync sees the new mutation records.
    context.written.forEach(_db.announceLocalChange);
    return result;
  }
}

class _Context implements core.WriteContext {
  _Context(this._uow);

  final DriftUnitOfWork _uow;

  /// The scopes this unit of work wrote a mutation record for.
  final written = <core.SyncScopeKey>{};

  @override
  Future<T> save<T extends core.Synchronizable>(
    T entity, {
    required core.MutationMetadata metadata,
  }) async {
    final store = _uow._stores.of(entity.entityType);
    final stored = await store.findJson(entity.id);
    final storedRevision = stored?['revision'] as int?;
    _requireFresh(entity, storedRevision);

    final json = store.encode(entity);
    json['revision'] = storedRevision == null
        ? entity.revision
        : storedRevision + 1;
    final saved = store.decode(json) as T;

    final scope = _scopeOf(entity, json);
    final follows = await _editFollowed(entity, storedRevision);
    await store.upsertJson(store.encode(saved));
    await _recordMutation(
      entityType: entity.entityType,
      entityId: entity.id,
      scope: scope,
      baseRevision: storedRevision,
      metadata: metadata,
      payload: savePayload(store.encode(saved), follows: follows),
    );
    return saved;
  }

  /// The unacknowledged edit of a pilot link that produced the revision this
  /// edit builds on, so the service can tell a follow-up of a waiting edit
  /// from an independent edit that reached the same revision.
  Future<core.Id?> _editFollowed(
    core.Synchronizable entity,
    int? storedRevision,
  ) async {
    if (entity.entityType != 'PilotImportLink' ||
        storedRevision == null ||
        _uow._db.profile == DatabaseProfile.server) {
      return null;
    }
    final rows = await _uow._mutations.where(
      "entity_type = 'PilotImportLink' AND entity_id = ? AND "
      "outcome IN ('Pending', 'Conflict')",
      [Variable<String>(entity.id.value)],
      orderBy: 'client_time DESC, id',
    );
    for (final row in rows) {
      final data = (row['payload'] as Map?)?['data'];
      final entity = data is Map ? data['entity'] : null;
      final made = entity is Map ? entity['revision'] : null;
      if (made == storedRevision) return core.Id.parse(row['id']! as String);
    }
    return null;
  }

  @override
  Future<void> delete(
    core.Synchronizable entity, {
    required core.MutationMetadata metadata,
  }) async {
    final store = _uow._stores.of(entity.entityType);
    final stored = await store.findJson(entity.id);
    if (stored == null) return;
    final storedRevision = stored['revision'] as int?;
    _requireFresh(entity, storedRevision);

    final scope = _scopeOf(entity, stored);
    await store.remove(entity.id);
    await _uow._tombstones.upsert(
      core.Tombstone(
        id: _uow._newId(),
        contestId: scope.contestId,
        ownerAccountId: scope.ownerAccountId,
        entityType: entity.entityType,
        entityId: entity.id,
        deletedAt: _uow._clock(),
      ).toJson(),
    );
    await _recordMutation(
      entityType: entity.entityType,
      entityId: entity.id,
      scope: scope,
      baseRevision: storedRevision,
      metadata: metadata,
      payload: deletePayload(),
    );
  }

  @override
  Future<T> append<T extends core.AppendOnly>(
    T entity, {
    required core.MutationMetadata metadata,
  }) async {
    final json = await _insertNew(entity);
    await _recordMutation(
      entityType: entity.entityType,
      entityId: entity.id,
      scope: _scopeOf(entity, json),
      baseRevision: null,
      metadata: metadata,
      payload: savePayload(json),
    );
    return entity;
  }

  @override
  Future<core.LandingTableWithResults> appendLandingTable(
    core.LandingTableWithResults table, {
    required core.MutationMetadata metadata,
  }) async {
    if (table.table.isSystem) {
      throw ArgumentError.value(
        table.table.id.value,
        'table',
        'must have an owner; system tables are seeded',
      );
    }
    final tableJson = await _insertNew(table.table);
    final results = _uow._stores.of('LandingResult');
    final resultJson = [
      for (final result in table.results) results.encode(result),
    ];
    for (final json in resultJson) {
      await results.upsertJson(json);
    }
    await _recordMutation(
      entityType: table.table.entityType,
      entityId: table.table.id,
      scope: _scopeOf(table.table, tableJson),
      baseRevision: null,
      metadata: metadata,
      payload: landingTablePayload(tableJson, resultJson),
    );
    return table;
  }

  @override
  Future<void> removeLandingTable(
    core.LandingTable table, {
    required core.MutationMetadata metadata,
  }) async {
    if (table.isSystem) {
      throw ArgumentError.value(
        table.id.value,
        'table',
        'must have an owner; system tables are never removed',
      );
    }
    final tables = _uow._stores.of('LandingTable');
    final stored = await tables.findJson(table.id);
    if (stored == null) return;
    await _uow._stores
        .of('LandingResult')
        .removeWhereId('landing_table_id', table.id);
    await tables.remove(table.id);
    final scope = _scopeOf(table, stored);
    await _uow._tombstones.upsert(
      core.Tombstone(
        id: _uow._newId(),
        contestId: scope.contestId,
        ownerAccountId: scope.ownerAccountId,
        entityType: table.entityType,
        entityId: table.id,
        deletedAt: _uow._clock(),
      ).toJson(),
    );
    await _recordMutation(
      entityType: table.entityType,
      entityId: table.id,
      scope: scope,
      baseRevision: null,
      metadata: metadata,
      payload: deletePayload(),
    );
  }

  @override
  Future<void> removeAssignment(
    core.MatrixAssignment assignment, {
    required core.MutationMetadata metadata,
  }) async {
    final store = _uow._stores.of('MatrixAssignment');
    final stored = await store.findJson(assignment.id);
    if (stored == null) return;
    final scope = _scopeOf(assignment, stored);
    // The marker's foreign key is deferred, so the row can go first.
    await store.remove(assignment.id);
    await clearSupersededMarkers(_uow._db, assignment.id);
    await _uow._tombstones.upsert(
      core.Tombstone(
        id: _uow._newId(),
        contestId: scope.contestId,
        ownerAccountId: scope.ownerAccountId,
        entityType: assignment.entityType,
        entityId: assignment.id,
        deletedAt: _uow._clock(),
      ).toJson(),
    );
    await _recordMutation(
      entityType: assignment.entityType,
      entityId: assignment.id,
      scope: scope,
      baseRevision: null,
      metadata: metadata,
      payload: deletePayload(),
    );
  }

  @override
  Future<core.MatrixAssignment> moveAssignment(
    core.MatrixAssignment moved, {
    required core.MutationMetadata metadata,
  }) async {
    final sourceId = moved.sourceAssignmentId;
    if (moved.assignmentType != core.AssignmentType.moved || sourceId == null) {
      throw ArgumentError.value(
        moved,
        'moved',
        'must be a Moved assignment with a source assignment',
      );
    }
    final source = await _uow._stores.of('MatrixAssignment').findJson(sourceId);
    if (source == null) {
      throw ArgumentError.value(sourceId, 'moved', 'source is not stored');
    }
    if (source['superseded_by_assignment_id'] != null) {
      throw core.AlreadySupersededError(assignmentId: sourceId);
    }

    // The old row is marked first, so it leaves the unique index on live
    // assignments before the new row enters it; the marker's foreign key is
    // deferred until the transaction commits.
    final marked = await _uow._db.customUpdate(
      portableSql(
        _uow._db,
        'UPDATE matrix_assignments SET superseded_by_assignment_id = ? '
        'WHERE id = ? AND superseded_by_assignment_id IS NULL',
      ),
      variables: [
        Variable<String>(moved.id.value),
        Variable<String>(sourceId.value),
      ],
      updates: {_uow._db.matrixAssignments},
    );
    if (marked != 1) throw core.AlreadySupersededError(assignmentId: sourceId);
    final json = await _insertNew(moved);

    await _recordMutation(
      entityType: moved.entityType,
      entityId: moved.id,
      scope: _scopeOf(moved, json),
      baseRevision: null,
      metadata: metadata,
      payload: moveAssignmentPayload(json, sourceId.value),
    );
    return moved;
  }

  /// Writes a row that must not exist yet; returns it as JSON.
  Future<Map<String, Object?>> _insertNew(core.AppendOnly entity) async {
    final store = _uow._stores.of(entity.entityType);
    if (await store.findJson(entity.id) != null) {
      throw core.AlreadyStoredError(
        entityType: entity.entityType,
        entityId: entity.id,
      );
    }
    final json = store.encode(entity);
    await store.upsertJson(json);
    return json;
  }

  void _requireFresh(core.Synchronizable entity, int? storedRevision) {
    if (storedRevision != null && storedRevision != entity.revision) {
      throw core.StaleRevisionError(
        entityType: entity.entityType,
        entityId: entity.id,
        expectedRevision: entity.revision,
        storedRevision: storedRevision,
      );
    }
  }

  /// The stream an entity's mutation belongs to. Only contest and director
  /// data are written locally; the rest arrives by replication.
  ({core.Id? contestId, core.Id? ownerAccountId}) _scopeOf(
    core.SyncScoped entity,
    Map<String, Object?> json,
  ) {
    switch (entity.syncScope) {
      case core.SyncScope.contest:
        final contestId = entity is core.Contest
            ? entity.id
            : core.Id.parse(json['contest_id']! as String);
        return (contestId: contestId, ownerAccountId: null);
      case core.SyncScope.director:
        return (
          contestId: null,
          ownerAccountId: core.Id.parse(json['owner_account_id']! as String),
        );
      case final other:
        throw StateError(
          '${entity.runtimeType} is ${other.name} data and is not written '
          'through the local unit of work',
        );
    }
  }

  Future<void> _recordMutation({
    required String entityType,
    required core.Id entityId,
    required ({core.Id? contestId, core.Id? ownerAccountId}) scope,
    required int? baseRevision,
    required core.MutationMetadata metadata,
    required Map<String, Object?> payload,
  }) async {
    final contestId = scope.contestId;
    final ownerId = scope.ownerAccountId;
    written.add(
      contestId != null
          ? core.ContestScopeKey(contestId)
          : core.DirectorScopeKey(ownerId!),
    );
    // On the service a direct write is already decided: it joins the scope's
    // log as accepted with the next sequence, so every installation pulls it.
    // On an installation it is a pending mutation in the outbox.
    final accepted = _uow._db.profile == DatabaseProfile.server;
    final sequence = accepted ? await _nextSequence(scope) : null;
    final record = core.MutationRecord(
      id: _uow._newId(),
      contestId: scope.contestId,
      ownerAccountId: scope.ownerAccountId,
      entityType: entityType,
      entityId: entityId,
      baseRevision: baseRevision,
      clientMutationId: metadata.clientMutationId,
      actorId: metadata.actorId,
      authority: metadata.authority,
      sourceInstallationId: metadata.sourceInstallationId,
      sourceDevice: metadata.sourceDevice,
      clientTime: metadata.clientTime,
      payload: payload,
      dependsOnMutationId: metadata.dependsOnMutationId,
      sequence: sequence,
      outcome: accepted
          ? core.MutationOutcome.accepted
          : core.MutationOutcome.pending,
      serverAcceptanceTime: accepted ? _uow._clock() : null,
    );
    await _uow._mutations.upsert(record.toJson());
  }

  /// The next sequence of [scope]'s log, inside the running transaction.
  Future<int> _nextSequence(
    ({core.Id? contestId, core.Id? ownerAccountId}) scope,
  ) async {
    final contestId = scope.contestId;
    final column = contestId != null ? 'contest_id' : 'owner_account_id';
    final id = (contestId ?? scope.ownerAccountId!).value;
    final highest = await highestScopeSequence(
      _uow._db,
      column: column,
      scopeId: id,
    );
    return highest + 1;
  }
}
