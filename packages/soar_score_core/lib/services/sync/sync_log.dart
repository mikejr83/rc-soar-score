import '../../enums/audit_action.dart';
import '../../enums/audit_outcome.dart';
import '../../enums/conflict_resolution.dart';
import '../../enums/authority.dart';
import '../../enums/mutation_outcome.dart';
import '../../models/id.dart';
import '../../models/sync/audit_event.dart';
import '../../models/sync/conflict_record.dart';
import '../../models/sync/mutation_record.dart';
import '../../repositories/sync_acceptor_store.dart';
import 'exchange_context.dart';
import 'mutation_payloads.dart';
import 'mutation_result.dart';
import 'sync_entity_catalog.dart';
import 'sync_exchange.dart';
import 'sync_mutation.dart';
import 'sync_scope_ids.dart';

/// Writes the decisions of the acceptor into the scope's log.
///
/// Every accepted change, and every conflict, takes the scope's next
/// sequence, which is how it reaches the other installations.
class SyncLog {
  /// Records [mutation] as accepted with [payload] (the entity as stored) and
  /// the next sequence of the scope.
  Future<MutationResult> accept(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    SyncMutation mutation,
    MutationPayload payload, {
    int? revision,
    AuditAction? audit,
    String? auditReason,
    Id? recordId,
  }) async {
    final sequence = await _nextSequence(tx, ctx);
    await tx.recordMutation(
      _record(
        ctx,
        mutation,
        id: recordId,
        outcome: MutationOutcome.accepted,
        payload: payload.toJson(),
        sequence: sequence,
        acceptedAt: ctx.clock(),
      ),
    );
    if (audit != null) {
      await appendAudit(
        tx,
        ctx,
        mutation,
        audit,
        AuditOutcome.success,
        reason: auditReason,
        resultingRevision: revision,
      );
    }
    return MutationResult(
      clientMutationId: mutation.clientMutationId,
      outcome: MutationOutcome.accepted,
      revision: revision,
      sequence: sequence,
    );
  }

  /// Records [mutation] as `Rejected`; it stays in the log so a retry of the
  /// same request returns the same answer.
  Future<MutationResult> reject(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    SyncMutation mutation,
    String reasonCode,
    String message, {
    int? currentRevision,
  }) async {
    await tx.recordMutation(
      _record(
        ctx,
        mutation,
        outcome: MutationOutcome.rejected,
        payload: mutation.payload,
        reasonCode: reasonCode,
        message: message,
        rejectedAt: ctx.clock(),
      ),
    );
    return MutationResult(
      clientMutationId: mutation.clientMutationId,
      outcome: MutationOutcome.rejected,
      reasonCode: reasonCode,
      currentRevision: currentRevision,
    );
  }

  /// Records [mutation] as a `Conflict`, creates the [ConflictRecord] for the
  /// director and sends it down the stream.
  ///
  /// [accepted] is the entity state the service holds; [competing] is what
  /// [mutation] asked for.
  Future<MutationResult> conflict(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    SyncMutation mutation, {
    required String reasonCode,
    required String message,
    required MutationPayload competing,
    Id? acceptedMutationId,
    Map<String, Object?>? accepted,
    int? currentRevision,
  }) async {
    final now = ctx.clock();
    final record = _record(
      ctx,
      mutation,
      outcome: MutationOutcome.conflict,
      payload: mutation.payload,
      reasonCode: reasonCode,
      message: message,
      rejectedAt: now,
    );
    await tx.recordMutation(record);
    final conflict = ConflictRecord(
      id: ctx.newId(),
      contestId: ctx.scope.contestIdOrNull,
      ownerAccountId: ctx.scope.ownerAccountIdOrNull,
      entityType: mutation.entityType,
      entityId: mutation.entityId,
      acceptedMutationId: acceptedMutationId,
      competingMutationId: record.id,
      reasonCode: reasonCode,
      reason: message,
      createdAt: now,
      acceptedPayload: accepted,
      competingPayload: competing.isDelete
          ? const {'operation': 'delete'}
          : competing.entity,
      entityRevision: currentRevision,
    );
    await tx.saveConflict(conflict);
    await emit(tx, ctx, conflict);
    ctx.conflicts.add(
      SyncConflictPointer(id: conflict.id, requiresAction: true),
    );
    await appendAudit(
      tx,
      ctx,
      mutation,
      AuditAction.conflict,
      AuditOutcome.conflict,
      reason: reasonCode,
    );
    return MutationResult(
      clientMutationId: mutation.clientMutationId,
      outcome: MutationOutcome.conflict,
      reasonCode: reasonCode,
      currentRevision: currentRevision,
    );
  }

  /// Stores a silent record: [mutation] won, and [competing] (a participant's
  /// earlier value) is kept for the director to see.
  Future<void> silentRecord(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    SyncMutation mutation, {
    required Id acceptedMutationId,
    required Id competingMutationId,
    required Map<String, Object?> accepted,
    required Map<String, Object?> competing,
    required int currentRevision,
  }) async {
    final now = ctx.clock();
    final conflict = ConflictRecord(
      id: ctx.newId(),
      contestId: ctx.scope.contestIdOrNull,
      ownerAccountId: ctx.scope.ownerAccountIdOrNull,
      entityType: mutation.entityType,
      entityId: mutation.entityId,
      acceptedMutationId: acceptedMutationId,
      competingMutationId: competingMutationId,
      reasonCode: 'director_over_participant',
      reason: "The director's value replaced a participant submission.",
      requiresAction: false,
      resolution: ConflictResolution.automatic,
      createdAt: now,
      acceptedPayload: accepted,
      competingPayload: competing,
      entityRevision: currentRevision,
    );
    await tx.saveConflict(conflict);
    await emit(tx, ctx, conflict);
    ctx.conflicts.add(
      SyncConflictPointer(id: conflict.id, requiresAction: false),
    );
  }

  /// Sends [conflict] down the scope's stream as a change of its own, which
  /// is how every installation of the scope learns of it.
  ///
  /// [clientMutationId] names the request that decided the conflict, so a
  /// retry of it finds this record; the service's own record gets a generated
  /// name.
  Future<MutationResult> emit(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    ConflictRecord conflict, {
    String? clientMutationId,
  }) async {
    final sequence = await _nextSequence(tx, ctx);
    final now = ctx.clock();
    final name = clientMutationId ?? 'server:${ctx.newId().value}';
    await tx.recordMutation(
      MutationRecord(
        id: ctx.newId(),
        contestId: ctx.scope.contestIdOrNull,
        ownerAccountId: ctx.scope.ownerAccountIdOrNull,
        sequence: sequence,
        entityType: SyncEntityCatalog.conflictRecordType,
        entityId: conflict.id,
        clientMutationId: name,
        authority: Authority.system,
        clientTime: now,
        serverAcceptanceTime: now,
        payload: MutationPayload.save(conflict.toJson()).toJson(),
        outcome: MutationOutcome.accepted,
      ),
    );
    return MutationResult(
      clientMutationId: name,
      outcome: MutationOutcome.accepted,
      sequence: sequence,
    );
  }

  Future<int> _nextSequence(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
  ) async => await tx.highestSequence(ctx.scope) + 1;

  MutationRecord _record(
    ExchangeContext ctx,
    SyncMutation mutation, {
    required MutationOutcome outcome,
    required Map<String, Object?> payload,
    int? sequence,
    String? reasonCode,
    String? message,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
    Id? id,
  }) => MutationRecord(
    id: id ?? ctx.newId(),
    contestId: ctx.scope.contestIdOrNull,
    ownerAccountId: ctx.scope.ownerAccountIdOrNull,
    sequence: sequence,
    entityType: mutation.entityType,
    entityId: mutation.entityId,
    baseRevision: mutation.baseRevision,
    clientMutationId: mutation.clientMutationId,
    actorId: ctx.accountId,
    authority: mutation.authority,
    sourceInstallationId: ctx.installationId,
    clientTime: mutation.clientTime,
    serverAcceptanceTime: acceptedAt,
    serverRejectionTime: rejectedAt,
    payload: payload,
    outcome: outcome,
    reasonCode: reasonCode,
    errorMessage: message,
    dependsOnMutationId: mutation.dependsOnMutationId,
  );

  Future<void> appendAudit(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    SyncMutation mutation,
    AuditAction action,
    AuditOutcome outcome, {
    String? reason,
    int? resultingRevision,
  }) => tx.appendAudit(
    AuditEvent(
      id: ctx.newId(),
      entityType: mutation.entityType,
      entityId: mutation.entityId,
      contestId: ctx.scope.contestIdOrNull,
      ownerAccountId: ctx.scope.ownerAccountIdOrNull,
      action: action,
      actorId: ctx.accountId,
      authority: mutation.authority,
      installationId: ctx.installationId,
      baseRevision: mutation.baseRevision,
      resultingRevision: resultingRevision,
      serverTimestamp: ctx.clock(),
      clientTimestamp: mutation.clientTime,
      reason: reason,
      outcome: outcome,
    ),
  );
}
