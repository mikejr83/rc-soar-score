import '../../enums/authority.dart';
import '../../enums/sync_reason_code.dart';
import '../../enums/tombstone_status.dart';
import '../../models/id.dart';
import '../../models/sync/conflict_record.dart';
import '../../models/sync/tombstone.dart';
import '../../repositories/sync_acceptor_store.dart';
import '../../repositories/sync_scope_key.dart';
import 'exchange_context.dart';
import 'mutation_payloads.dart';
import 'mutation_result.dart';
import 'sync_exchange.dart';
import 'sync_log.dart';
import 'sync_mutation.dart';
import 'sync_scope_ids.dart';

/// What happens when installations of one director disagree about which
/// participant a GliderScore pilot is linked to.
///
/// Two installations that were offline can each create a link for the same
/// pilot. The service keeps the one it saw first, and keeps the other as a
/// conflict for the director, with the latest edit of that installation's
/// queue (a later edit of the same link replaces the earlier one in the
/// review). Rules:
///
/// - Different participants: a conflict the director decides. Any change to
///   either side while it waits closes it and opens a new one, so a decision
///   is always about the comparison that was shown.
/// - The same participant: nothing to decide. The stored link stays and the
///   saved GliderScore details are compared at the next import, field by
///   field.
/// - A deleted participant stays deleted: its links go with it, a link edit
///   that names it is refused, and a review that depended on it is closed.
class PilotLinkCollisions {
  const PilotLinkCollisions(this._log);

  final SyncLog _log;

  static const entityType = 'PilotImportLink';
  static const _profileType = 'ParticipantProfile';

  /// The reason of a link that matched the stored one and needs no review.
  static final sameParticipantReason = SyncReasonCode.sameParticipantLink.code;

  /// Whether a mutation of [type] is a pilot link of a director's own data.
  static bool handles(ExchangeContext ctx, String type) =>
      type == entityType && ctx.scope is DirectorScopeKey;

  /// Why a link may not name its participant, or null.
  Future<(SyncReasonCode, String)?> targetProblem(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    Map<String, Object?> link,
  ) async {
    final target = link['participant_profile_id'];
    if (target is! String) {
      return (
        SyncReasonCode.invalidPayload,
        'The pilot link names no participant.',
      );
    }
    final profile = await tx.findEntity(_profileType, Id.parse(target));
    if (profile == null) {
      final deleted =
          await tx.findTombstone(_profileType, Id.parse(target)) != null;
      return (
        deleted ? SyncReasonCode.entityDeleted : SyncReasonCode.invalidPayload,
        deleted
            ? 'The participant was deleted, so the pilot link was not kept. '
                  'Link the pilot again at the next import.'
            : 'The pilot link names a participant the service does not have.',
      );
    }
    if (profile['owner_account_id'] != link['owner_account_id']) {
      return (
        SyncReasonCode.unauthorized,
        'The participant belongs to another account.',
      );
    }
    return null;
  }

  /// The decision for a link that is not stored under its own id.
  ///
  /// Returns null when no other link holds the pilot, and the link can be
  /// stored. Otherwise the pilot is taken: the result is the conflict (or the
  /// quiet record) that keeps the offered link.
  Future<MutationResult?> collide(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    SyncMutation m,
    MutationPayload payload,
  ) async {
    final entity = payload.entity;
    final held = await _holding(tx, ctx, entity);
    if (held == null) return null;

    // The offered link replaces whatever this installation offered before.
    for (final earlier in await _pending(tx, ctx)) {
      if (earlier.competingPayload?['id'] == m.entityId.value) {
        await _log.closeAutomatically(tx, ctx, earlier);
      }
    }
    final agree =
        held['participant_profile_id'] == entity['participant_profile_id'];
    return _log.conflict(
      tx,
      ctx,
      m,
      reasonCode: agree
          ? sameParticipantReason
          : SyncReasonCode.uniqueViolation.code,
      message: agree
          ? 'Both devices linked this pilot to the same participant. The '
                'saved GliderScore details are compared at the next import.'
          : 'Two devices linked this GliderScore pilot to different '
                'participants. Review the links.',
      competing: payload,
      accepted: held,
      currentRevision: held['revision'] as int?,
      conflictEntityId: Id.parse(held['id']! as String),
      requiresAction: !agree,
    );
  }

  /// A link of an installation's queue was deleted before the director
  /// decided: it no longer competes.
  Future<void> withdrawn(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    Id linkId,
  ) async {
    for (final conflict in await _pending(tx, ctx)) {
      if (conflict.competingPayload?['id'] == linkId.value) {
        await _log.closeAutomatically(tx, ctx, conflict);
      }
    }
  }

  /// The stored link [linkId] changed or was removed. Reviews of it that are
  /// waiting were about the old state: each is closed and, if the two links
  /// still disagree, opened again with the comparison as it is now.
  Future<void> storedLinkChanged(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    Id linkId, {
    Id? except,
  }) async {
    final current = await tx.findEntity(entityType, linkId);
    for (final conflict in await _pending(tx, ctx)) {
      if (conflict.entityId != linkId || conflict.id == except) continue;
      if (current != null && current['revision'] == conflict.entityRevision) {
        continue;
      }
      await _log.closeAutomatically(tx, ctx, conflict);
      final competing = conflict.competingPayload;
      if (competing == null) continue;
      Map<String, Object?>? holder = current;
      if (current == null) {
        // The first contender takes the place of the removed link; any other
        // contender is then reviewed against the link that now holds the pilot.
        await _promote(tx, ctx, conflict, competing);
        holder = await _holding(tx, ctx, competing);
      }
      if (holder == null ||
          holder['participant_profile_id'] ==
              competing['participant_profile_id']) {
        continue;
      }
      await _reopen(tx, ctx, conflict, holder, competing);
    }
  }

  Future<void> _reopen(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    ConflictRecord conflict,
    Map<String, Object?> holder,
    Map<String, Object?> competing,
  ) async {
    final reopened = ConflictRecord(
      id: ctx.newId(),
      ownerAccountId: conflict.ownerAccountId,
      entityType: entityType,
      entityId: Id.parse(holder['id']! as String),
      competingMutationId: conflict.competingMutationId,
      reasonCode: conflict.reasonCode,
      reason:
          'The pilot link changed while it waited for a decision. Review '
          'the links again.',
      createdAt: ctx.clock(),
      acceptedPayload: holder,
      competingPayload: competing,
      entityRevision: holder['revision'] as int?,
    );
    await tx.saveConflict(reopened);
    await _log.emit(tx, ctx, reopened);
    ctx.conflicts.add(
      SyncConflictPointer(id: reopened.id, requiresAction: true),
    );
  }

  /// An edit of a link both installations already hold, made on a revision
  /// that is no longer the stored one.
  ///
  /// Returns null when the edit builds on the stored link and can be stored.
  /// Otherwise the two installations disagree: a different participant is a
  /// review for the director, the same participant is kept quietly. An edit
  /// that follows an earlier edit of a waiting review replaces it.
  Future<MutationResult?> competeOnShared(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    SyncMutation m,
    MutationPayload payload,
    Map<String, Object?> stored,
  ) async {
    final entity = payload.entity;
    final base = m.baseRevision;
    ConflictRecord? successorOf;
    for (final earlier in await _pending(tx, ctx)) {
      if (earlier.entityId == m.entityId &&
          base != null &&
          earlier.competingPayload?['id'] == m.entityId.value &&
          earlier.competingPayload?['revision'] == base) {
        successorOf = earlier;
      }
    }
    if (successorOf == null && base == stored['revision']) return null;
    if (successorOf != null) {
      await _log.closeAutomatically(tx, ctx, successorOf);
    }
    final agree =
        stored['participant_profile_id'] == entity['participant_profile_id'];
    return _log.conflict(
      tx,
      ctx,
      m,
      reasonCode: agree
          ? sameParticipantReason
          : SyncReasonCode.uniqueViolation.code,
      message: agree
          ? 'Both devices linked this pilot to the same participant. The '
                'saved GliderScore details are compared at the next import.'
          : 'Two devices linked this GliderScore pilot to different '
                'participants. Review the links.',
      competing: payload,
      accepted: stored,
      currentRevision: stored['revision'] as int?,
      requiresAction: !agree,
    );
  }

  /// After the director kept the stored link of a review whose competing link
  /// shares its id, publish the stored link again under a newer revision so
  /// the installation that lost replaces its own edit.
  Future<void> republishKept(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    ConflictRecord conflict,
  ) async {
    if (conflict.competingPayload?['id'] != conflict.entityId.value) return;
    final stored = await tx.findEntity(entityType, conflict.entityId);
    if (stored == null) return;
    final entity = {...stored, 'revision': (stored['revision'] as int) + 1};
    await tx.writeEntity(entityType, entity);
    await _log.accept(
      tx,
      ctx,
      SyncMutation(
        id: ctx.newId(),
        clientMutationId: 'server:pilot-link-republished:${conflict.id.value}',
        entityType: entityType,
        entityId: conflict.entityId,
        authority: Authority.system,
        clientTime: ctx.clock(),
        payload: MutationPayload.save(entity).toJson(),
      ),
      MutationPayload.save(entity),
      revision: entity['revision'] as int?,
    );
    await storedLinkChanged(tx, ctx, conflict.entityId, except: conflict.id);
  }

  /// A participant was deleted. Its links go with it, and so do the reviews
  /// that named it; the deletion is kept and the pilot is linked again at the
  /// next import.
  Future<void> participantDeleted(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    SyncMutation m,
    Id profileId,
  ) async {
    if (ctx.scope is! DirectorScopeKey) return;
    final links = await tx.findEntitiesWhere(
      entityType,
      'participant_profile_id',
      profileId,
    );
    for (final link in links) {
      final id = Id.parse(link['id']! as String);
      await tx.removeEntity(entityType, id);
      await _tombstone(tx, ctx, id, m);
      await _log.accept(
        tx,
        ctx,
        SyncMutation(
          id: ctx.newId(),
          clientMutationId: 'server:participant-deleted:${id.value}',
          entityType: entityType,
          entityId: id,
          authority: Authority.system,
          clientTime: ctx.clock(),
          payload: MutationPayload.delete.toJson(),
        ),
        MutationPayload.delete,
      );
      await storedLinkChanged(tx, ctx, id);
    }
    for (final conflict in await _pending(tx, ctx)) {
      if (conflict.competingPayload?['participant_profile_id'] ==
          profileId.value) {
        await _log.closeAutomatically(tx, ctx, conflict);
      }
    }
  }

  /// The competing link takes the place of a stored one that was removed.
  Future<void> _promote(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    ConflictRecord conflict,
    Map<String, Object?> competing,
  ) async {
    if (competing['operation'] == 'delete') return;
    if (await targetProblem(tx, ctx, competing) != null) return;
    final id = Id.parse(competing['id']! as String);
    if (await tx.findTombstone(entityType, id) != null) return;
    if (await _holding(tx, ctx, competing) != null) return;
    await tx.writeEntity(entityType, competing);
    await _log.accept(
      tx,
      ctx,
      SyncMutation(
        id: ctx.newId(),
        clientMutationId: 'server:pilot-link-kept:${conflict.id.value}',
        entityType: entityType,
        entityId: id,
        authority: Authority.system,
        clientTime: ctx.clock(),
        payload: MutationPayload.save(competing).toJson(),
      ),
      MutationPayload.save(competing),
      revision: competing['revision'] as int?,
    );
  }

  Future<void> _tombstone(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    Id id,
    SyncMutation m,
  ) async {
    final now = ctx.clock();
    await tx.saveTombstone(
      Tombstone(
        id: ctx.newId(),
        ownerAccountId: ctx.scope.ownerAccountIdOrNull,
        entityType: entityType,
        entityId: id,
        status: TombstoneStatus.acknowledged,
        deletedAt: m.clientTime,
        acknowledgedAt: now,
        purgeAfter: now.add(Tombstone.retention),
      ),
    );
  }

  Future<List<ConflictRecord>> _pending(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
  ) async => [
    for (final conflict in await tx.conflictsNeedingAction(ctx.scope))
      if (conflict.entityType == entityType &&
          conflict.reasonCode == SyncReasonCode.uniqueViolation.code)
        conflict,
  ];

  /// The stored link, other than [link] itself, for the same source pilot.
  Future<Map<String, Object?>?> _holding(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    Map<String, Object?> link,
  ) async {
    final owner = ctx.scope.ownerAccountIdOrNull;
    if (owner == null) return null;
    for (final candidate in await tx.findEntitiesWhere(
      entityType,
      'owner_account_id',
      owner,
    )) {
      if (candidate['id'] != link['id'] &&
          candidate['source_system'] == link['source_system'] &&
          candidate['source_pilot_no'] == link['source_pilot_no']) {
        return candidate;
      }
    }
    return null;
  }
}
