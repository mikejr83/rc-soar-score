import 'package:drift/drift.dart' show Variable;
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../database.dart';
import 'entity_stores.dart';
import 'mutation_payload.dart';
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
  Future<T> run<T>(Future<T> Function(core.WriteContext context) body) =>
      _db.transaction(() => body(_Context(this)));
}

class _Context implements core.WriteContext {
  _Context(this._uow);

  final DriftUnitOfWork _uow;

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
    await store.upsertJson(store.encode(saved));
    await _recordMutation(
      entityType: entity.entityType,
      entityId: entity.id,
      scope: scope,
      baseRevision: storedRevision,
      metadata: metadata,
      payload: savePayload(store.encode(saved)),
    );
    return saved;
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
  }) {
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
    );
    return _uow._mutations.upsert(record.toJson());
  }
}
