import '../../enums/audit_action.dart';
import '../../enums/audit_outcome.dart';
import '../../enums/authority.dart';
import '../../enums/conflict_resolution.dart';
import '../../enums/conflict_resolution_choice.dart';
import '../../enums/mutation_outcome.dart';
import '../../enums/sync_reason_code.dart';
import '../../enums/tombstone_status.dart';
import '../../errors/entity_not_found_error.dart';
import '../../errors/forbidden_error.dart';
import '../../errors/sync_constraint_error.dart';
import '../../errors/sync_payload_error.dart';
import '../../models/id.dart';
import '../../models/sync/conflict_record.dart';
import '../../models/sync/tombstone.dart';
import '../../repositories/sync_acceptor_store.dart';
import '../../repositories/sync_scope_key.dart';
import 'exchange_context.dart';
import 'mutation_payloads.dart';
import 'mutation_replay.dart';
import 'mutation_result.dart';
import 'pilot_link_collisions.dart';
import 'sync_entity_catalog.dart';
import 'sync_log.dart';
import 'sync_mutation.dart';
import 'sync_scope_guard.dart';
import 'sync_scope_ids.dart';

/// Applies the director's decision for a conflict.
///
/// A decision is itself a mutation: it is idempotent on its
/// `client_mutation_id`, takes its place in the scope's sequence and is
/// audited. The resolved `ConflictRecord` reaches every installation as a new
/// revision of the same entity.
class ConflictResolver {
  ConflictResolver(this._store, this._clock, this._newId, {SyncLog? log})
    : _log = log ?? SyncLog(),
      _links = PilotLinkCollisions(log ?? SyncLog());

  final SyncAcceptorStore _store;
  final DateTime Function() _clock;
  final Id Function() _newId;
  final SyncLog _log;
  final PilotLinkCollisions _links;

  /// The conflict [id], so the caller can check the scope and take its lock.
  Future<ConflictRecord> find(Id id, {required Id accountId}) =>
      _store.transaction((tx) async {
        final conflict = await tx.findConflict(id);
        if (conflict == null) {
          throw EntityNotFoundError(entityType: 'ConflictRecord', entityId: id);
        }
        final owner = conflict.contestId == null
            ? conflict.ownerAccountId
            : await _contestOwner(tx, conflict.contestId!);
        if (owner != accountId) {
          throw ForbiddenError(
            'not_director',
            'only the director of the scope decides its conflicts',
          );
        }
        return conflict;
      });

  Future<MutationResult> resolve({
    required Id accountId,
    required Id conflictId,
    required String clientMutationId,
    required ConflictResolutionChoice choice,
    Map<String, Object?>? payload,
  }) async {
    try {
      return await _store.transaction(
        (tx) => _resolve(
          tx,
          accountId,
          conflictId,
          clientMutationId,
          choice,
          payload,
        ),
      );
    } on SyncPayloadError catch (e) {
      return _refused(clientMutationId, SyncReasonCode.invalidPayload, e);
    } on SyncConstraintError catch (e) {
      return _refused(
        clientMutationId,
        e.kind == SyncConstraintKind.unique
            ? SyncReasonCode.uniqueViolation
            : SyncReasonCode.invalidPayload,
        e,
      );
    }
  }

  MutationResult _refused(String id, SyncReasonCode reason, Object error) =>
      MutationResult(
        clientMutationId: id,
        outcome: MutationOutcome.rejected,
        reasonCode: reason.code,
      );

  Future<MutationResult> _resolve(
    SyncAcceptorTransaction tx,
    Id accountId,
    Id conflictId,
    String clientMutationId,
    ConflictResolutionChoice choice,
    Map<String, Object?>? merged,
  ) async {
    final conflict = await tx.findConflict(conflictId);
    if (conflict == null) {
      throw EntityNotFoundError(
        entityType: 'ConflictRecord',
        entityId: conflictId,
      );
    }
    final scope = conflict.contestId != null
        ? ContestScopeKey(conflict.contestId!) as SyncScopeKey
        : DirectorScopeKey(conflict.ownerAccountId!);
    final prior = await tx.findMutation(scope, clientMutationId);
    if (prior != null) return replayDecision(tx, prior);

    MutationResult refuse(SyncReasonCode reason) => MutationResult(
      clientMutationId: clientMutationId,
      outcome: MutationOutcome.rejected,
      reasonCode: reason.code,
    );
    if (conflict.resolution != ConflictResolution.pending ||
        !conflict.requiresAction) {
      return refuse(SyncReasonCode.staleBase);
    }
    if (choice == ConflictResolutionChoice.merged && merged == null) {
      return refuse(SyncReasonCode.invalidPayload);
    }
    final ctx = ExchangeContext(
      scope: scope,
      accountId: accountId,
      clock: _clock,
      newId: _newId,
    );
    Map<String, Object?>? chosen;
    final isLinkReview =
        conflict.entityType == PilotLinkCollisions.entityType &&
        conflict.reasonCode == SyncReasonCode.uniqueViolation.code;
    if (isLinkReview) {
      // The director decides about the comparison that was shown: if either
      // link moved since, the review was replaced and this one is stale.
      final current = await tx.findEntity(
        conflict.entityType,
        conflict.entityId,
      );
      if (current == null || current['revision'] != conflict.entityRevision) {
        return refuse(SyncReasonCode.staleBase);
      }
      if (choice == ConflictResolutionChoice.merged) {
        // The director picked another participant for the pilot.
        final picked = merged?['participant_profile_id'];
        if (picked is! String) return refuse(SyncReasonCode.invalidPayload);
        chosen = {...current, 'participant_profile_id': picked};
        final problem = await _links.targetProblem(tx, ctx, chosen);
        if (problem != null) return refuse(problem.$1);
      }
      final competing = conflict.competingPayload;
      if (choice == ConflictResolutionChoice.tookCompeting &&
          (competing == null ||
              await _links.targetProblem(tx, ctx, competing) != null)) {
        return refuse(SyncReasonCode.entityDeleted);
      }
    }
    final now = _clock();
    final resolved = ConflictRecord(
      id: conflict.id,
      contestId: conflict.contestId,
      ownerAccountId: conflict.ownerAccountId,
      entityType: conflict.entityType,
      entityId: conflict.entityId,
      acceptedMutationId: conflict.acceptedMutationId,
      competingMutationId: conflict.competingMutationId,
      reasonCode: conflict.reasonCode,
      reason: conflict.reason,
      requiresAction: conflict.requiresAction,
      resolution: ConflictResolution.manual,
      resolutionChoice: choice,
      createdAt: conflict.createdAt,
      resolvedAt: now,
      resolvedBy: accountId,
      acceptedPayload: conflict.acceptedPayload,
      competingPayload: conflict.competingPayload,
      entityRevision: conflict.entityRevision,
    );

    final decision = SyncMutation(
      id: _newId(),
      clientMutationId: clientMutationId,
      entityType: conflict.entityType,
      entityId: conflict.entityId,
      baseRevision: conflict.entityRevision,
      authority: Authority.director,
      clientTime: now,
      payload: const {},
    );

    if (choice == ConflictResolutionChoice.keptAccepted) {
      final emitted = await _log.emit(
        tx,
        ctx,
        resolved,
        clientMutationId: clientMutationId,
      );
      await tx.saveConflict(resolved);
      await _audit(tx, ctx, decision, AuditAction.conflictRejected);
      return emitted;
    }

    if (scope is ContestScopeKey) {
      final contest = await tx.findEntity('Contest', scope.contestId);
      if (contest != null &&
          conflict.entityType != 'Contest' &&
          (contest['admin_lock'] == 'Locked' ||
              contest['lifecycle_state'] == 'Completed')) {
        return refuse(SyncReasonCode.locked);
      }
    }
    if (await tx.findTombstone(conflict.entityType, conflict.entityId) !=
        null) {
      return refuse(SyncReasonCode.entityDeleted);
    }

    final taken = choice == ConflictResolutionChoice.merged
        ? MutationPayload.save(chosen ?? merged!)
        : _competing(conflict);
    final result = await _apply(tx, ctx, conflict, decision, taken);
    if (result.outcome == MutationOutcome.rejected) return result;
    await tx.saveConflict(resolved);
    await _log.emit(tx, ctx, resolved);
    if (isLinkReview) {
      // Another review of the same link compared the state before this one.
      await _links.storedLinkChanged(
        tx,
        ctx,
        conflict.entityId,
        except: conflict.id,
      );
    }
    await _audit(tx, ctx, decision, AuditAction.conflictAccepted);
    return result;
  }

  MutationPayload _competing(ConflictRecord conflict) {
    final competing = conflict.competingPayload ?? const {};
    return competing['operation'] == 'delete'
        ? MutationPayload.delete
        : MutationPayload.save(competing);
  }

  Future<MutationResult> _apply(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    ConflictRecord conflict,
    SyncMutation decision,
    MutationPayload taken,
  ) async {
    final type = conflict.entityType;
    final id = conflict.entityId;
    final kind = SyncEntityCatalog.of(type);
    if (kind == null) throw SyncPayloadError('$type cannot be decided');

    final stored = await tx.findEntity(type, id);
    final entity = {...taken.entity};
    if (type == 'PilotImportLink' &&
        conflict.reasonCode == SyncReasonCode.uniqueViolation.code) {
      if (stored == null || stored['revision'] != conflict.entityRevision) {
        throw SyncPayloadError(
          'The accepted pilot link changed after this conflict was recorded.',
        );
      }
      entity['id'] = id.value;
      entity['created_at'] = stored['created_at'];
    }
    // The decision may only write the conflict's own entity, in the
    // conflict's own scope, as an ordinary mutation would be allowed to.
    final problem = await SyncScopeGuard.writeProblem(
      tx,
      ctx,
      kind,
      id,
      taken.isDelete ? MutationPayload.delete : MutationPayload.save(entity),
      stored,
    );
    if (problem != null) {
      return MutationResult(
        clientMutationId: decision.clientMutationId,
        outcome: MutationOutcome.rejected,
        reasonCode: problem.$1.code,
      );
    }

    if (taken.isDelete) {
      await tx.removeEntity(type, id);
      final now = _clock();
      await tx.saveTombstone(
        Tombstone(
          id: _newId(),
          contestId: ctx.scope.contestIdOrNull,
          ownerAccountId: ctx.scope.ownerAccountIdOrNull,
          entityType: type,
          entityId: id,
          status: TombstoneStatus.acknowledged,
          deletedAt: now,
          acknowledgedAt: now,
          purgeAfter: now.add(Tombstone.retention),
        ),
      );
      return _log.accept(
        tx,
        ctx,
        decision,
        MutationPayload.delete,
        audit: AuditAction.deletion,
      );
    }

    switch (kind.shape) {
      case SyncEntityShape.revisioned:
        entity['revision'] = ((stored?['revision'] as int?) ?? 0) + 1;
      case SyncEntityShape.appendOnly:
      case SyncEntityShape.unrevisioned:
        await _renumber(tx, ctx, type, entity);
    }
    await tx.writeEntity(type, entity);
    return _log.accept(
      tx,
      ctx,
      decision,
      MutationPayload.save(entity),
      revision: entity['revision'] as int?,
    );
  }

  /// Gives an entity that was refused its turn in a numbered series the next
  /// number, now that the director chose it.
  Future<void> _renumber(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    String type,
    Map<String, Object?> entity,
  ) async {
    switch (type) {
      case 'ContestConfigurationRevision':
        final held = await tx.findEntitiesWhere(
          type,
          'contest_id',
          ctx.scope.contestIdOrNull!,
        );
        entity['revision_number'] =
            held.fold<int>(0, (m, r) => _max(m, r['revision_number'])) + 1;
      case 'OfficialScore':
        final held = await tx.findEntitiesWhere(
          type,
          'score_placeholder_id',
          Id.parse(entity['score_placeholder_id']! as String),
        );
        entity['score_revision'] =
            held.fold<int>(0, (m, r) => _max(m, r['score_revision'])) + 1;
    }
  }

  int _max(int a, Object? b) => b is int && b > a ? b : a;

  Future<void> _audit(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    SyncMutation decision,
    AuditAction action,
  ) => _log.appendAudit(tx, ctx, decision, action, AuditOutcome.success);

  Future<Id?> _contestOwner(SyncAcceptorTransaction tx, Id contestId) async {
    final contest = await tx.findEntity('Contest', contestId);
    final owner = contest?['owner_account_id'];
    return owner is String ? Id.parse(owner) : null;
  }
}
