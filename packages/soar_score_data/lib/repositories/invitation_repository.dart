import 'package:drift/drift.dart' show SqlDialect, UpdateKind, Variable;
import 'package:soar_score_core/soar_score_core.dart' as core;

import 'audit_event_repository.dart';
import 'drift_repository.dart';
import '../sync/sql_placeholders.dart';
import 'latest_timestamps.dart';

/// Invitations in the database; backend only, so written without a
/// mutation.
class InvitationRepository extends DriftRepository
    implements core.InvitationRepository {
  InvitationRepository(super.db, {super.stores});

  late final _store = backendStore<core.Invitation>('Invitation');
  late final _audits = AuditEventRepository(db, stores: stores);

  @override
  Future<core.Invitation?> findById(core.Id id) async => _store.find(id);

  @override
  Future<core.Invitation?> findByClientMutationId({
    required core.Id contestId,
    required String clientMutationId,
  }) async {
    final found = await _store.whereText(
      'client_mutation_id',
      clientMutationId,
      orderBy: 'id',
    );
    return found.where((i) => i.contestId == contestId).firstOrNull;
  }

  @override
  Future<core.Invitation?> findByProtectedCredential(String credential) async {
    final found = await _store.whereText(
      'protected_credential',
      credential,
      orderBy: 'id',
    );
    return found.firstOrNull;
  }

  @override
  Future<List<core.Invitation>> listForParticipation(
    core.Id contestParticipationId,
  ) async => _store.whereId(
    'contest_participation_id',
    contestParticipationId,
    orderBy: 'invitation_revision',
  );

  @override
  Future<List<core.Invitation>> listForParticipations(
    Iterable<core.Id> contestParticipationIds,
  ) async =>
      (await _store.whereIdIn(
        'contest_participation_id',
        contestParticipationIds,
      ))..sort((a, b) {
        final byParticipation = a.contestParticipationId.value.compareTo(
          b.contestParticipationId.value,
        );
        return byParticipation != 0
            ? byParticipation
            : a.invitationRevision.compareTo(b.invitationRevision);
      });

  @override
  Future<core.Invitation?> findActiveForParticipation(
    core.Id contestParticipationId,
  ) async {
    final all = await listForParticipation(contestParticipationId);
    return all.where((i) => i.isActive).firstOrNull;
  }

  @override
  Future<List<core.Invitation>> listForContest(core.Id contestId) async =>
      _store.whereId('contest_id', contestId, orderBy: 'id');

  @override
  Future<Map<core.Id, DateTime>> latestIssuedAtForContests(
    Iterable<core.Id> contestIds,
  ) => latestTimestampByContest(
    db,
    table: 'invitations',
    column: 'issued_at',
    contestIds: contestIds,
  );

  @override
  Future<core.Invitation> save(core.Invitation invitation) async {
    await _store.upsertJson(_store.encode(invitation));
    return invitation;
  }

  @override
  Future<bool> redeem(
    core.Id invitationId, {
    required core.Id? expectedRedeemer,
    required core.Id newRedeemer,
    required DateTime usedAt,
    ({core.Id profileId, core.Id accountId})? requireConfirmedLinkOf,
  }) => db.transaction(() async {
    final link = requireConfirmedLinkOf;
    if (link != null) {
      // The same row lock an unlink and a claim take (PostgreSQL; SQLite has
      // one writer), so the link cannot end between this check and the write.
      final lock = db.executor.dialect == SqlDialect.postgres
          ? ' FOR UPDATE'
          : '';
      final held = await db
          .customSelect(
            portableSql(
              db,
              'SELECT id FROM participant_account_links '
              'WHERE participant_profile_id = ? AND account_id = ? '
              "AND status = 'Confirmed'$lock",
            ),
            variables: [
              Variable<String>(link.profileId.value),
              Variable<String>(link.accountId.value),
            ],
          )
          .get();
      if (held.isEmpty) return false;
    }
    final stamp = const core.UtcTimestampConverter().toJson(usedAt.toUtc());
    // `IS ?` is not portable to PostgreSQL, so a missing redeemer is its own
    // condition.
    final expected = expectedRedeemer == null
        ? 'redeemed_by_account_id IS NULL'
        : 'redeemed_by_account_id = ?';
    final changed = await db.customUpdate(
      portableSql(
        db,
        'UPDATE invitations SET redeemed_by_account_id = ?, '
        'first_used_at = COALESCE(first_used_at, ?), last_used_at = ? '
        "WHERE id = ? AND state = 'Active' AND $expected",
      ),
      variables: [
        Variable<String>(newRedeemer.value),
        Variable<String>(stamp),
        Variable<String>(stamp),
        Variable<String>(invitationId.value),
        if (expectedRedeemer != null) Variable<String>(expectedRedeemer.value),
      ],
      updates: {
        db.allTables.firstWhere((t) => t.actualTableName == 'invitations'),
      },
      updateKind: UpdateKind.update,
    );
    return changed > 0;
  });

  @override
  Future<void> saveIssued(
    List<core.Invitation> invitations,
    List<core.AuditEvent> audits,
  ) => db.transaction(() async {
    for (final invitation in invitations) {
      await _store.upsertJson(_store.encode(invitation));
    }
    for (final audit in audits) {
      await _audits.append(audit);
    }
  });
}
