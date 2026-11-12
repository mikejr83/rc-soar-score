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
import 'sync_exchange.dart';
import 'sync_log.dart';
import 'sync_mutation.dart';
import 'sync_scope_ids.dart';

/// The rules for remembered GliderScore pilot links on the service.
///
/// One installation manages the links of a director (GliderScore is one source
/// per director): the first to write one. The service refuses link writes
/// from any other installation, whether made live or queued offline and sent
/// after reconnecting, so installations cannot disagree about a link. Other
/// installations import with a one-time choice instead (nothing remembered
/// changes).
///
/// Disagreements that already exist are decided by the director in Account
/// sync. While one waits, any change to either side closes it and opens a new
/// one, so a decision is always about the comparison that was shown. A deleted
/// participant stays deleted: its links go with it, a link edit that names it
/// is refused, and a review that depended on it is closed.
class PilotLinkCollisions {
  const PilotLinkCollisions(this._log);

  final SyncLog _log;

  static const entityType = 'PilotImportLink';
  static const _profileType = 'ParticipantProfile';

  /// Whether a mutation of [type] is a pilot link of a director's own data.
  static bool handles(ExchangeContext ctx, String type) =>
      type == entityType && ctx.scope is DirectorScopeKey;

  /// Why the installation that sent [m] may not write links, or null.
  ///
  /// The managing installation is the one that sent the first link of the
  /// director's log. Decisions and the service's own changes carry no
  /// installation and are never refused.
  Future<(SyncReasonCode, String)?> writerProblem(
    SyncAcceptorTransaction tx,
    ExchangeContext ctx,
    SyncMutation m,
  ) async {
    final sender = ctx.installationId;
    if (sender == null || m.authority == Authority.system) return null;
    final manager = await _manager(tx, ctx);
    if (manager == null || manager == sender) return null;
    return (
      SyncReasonCode.notLinkManager,
      'Another installation manages the remembered GliderScore pilot links. '
          'Import without remembered links here, or manage them there.',
    );
  }

  Future<Id?> _manager(SyncAcceptorTransaction tx, ExchangeContext ctx) async {
    var after = 0;
    while (true) {
      final page = await tx.acceptedAfter(ctx.scope, after, limit: 500);
      if (page.isEmpty) return null;
      for (final record in page) {
        if (record.entityType == entityType &&
            record.authority != Authority.system &&
            record.sourceInstallationId != null) {
          return record.sourceInstallationId;
        }
      }
      after = page.last.sequence!;
    }
  }

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
