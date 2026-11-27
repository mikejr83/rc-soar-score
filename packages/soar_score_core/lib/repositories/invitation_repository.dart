import '../models/id.dart';
import '../models/scores/invitation.dart';
import '../models/sync/audit_event.dart';

/// Abstract persistence contract for [Invitation]s.
///
/// Backend only: writes record no `MutationRecord`, and an installation
/// throws a `BackendOnlyError`. Invitations are never deleted, so there is no
/// remove; they stay as the access history of the scores submitted under
/// them. The stored protected credential comes back with each invitation, so
/// callers must keep it out of logs.
abstract interface class InvitationRepository {
  Future<Invitation?> findById(Id id);

  /// The invitation of [contestId] issued under [clientMutationId], or
  /// `null`. Issuing and revoking use it to stay idempotent.
  Future<Invitation?> findByClientMutationId({
    required Id contestId,
    required String clientMutationId,
  });

  /// The invitation whose stored protected credential equals [credential],
  /// or `null`.
  Future<Invitation?> findByProtectedCredential(String credential);

  /// The id of the invitation whose delivery outcomes hold an email with the
  /// provider's [messageId], or `null`. [messageId] must be letters, digits
  /// and hyphens only; anything else finds nothing.
  ///
  /// Used to attach a bounce or complaint to the email it is about. It reads
  /// the outcomes of every invitation, so it is for rare provider reports,
  /// not for request paths.
  Future<Id?> findIdByDeliveryMessageId(String messageId);

  /// The ids of the invitations with an email send still in flight (an
  /// outcome stored as `sending`). Same cost as [findIdByDeliveryMessageId].
  Future<List<Id>> listIdsWithSendingEmail();

  /// Every invitation of [contestParticipationId], oldest revision first.
  Future<List<Invitation>> listForParticipation(Id contestParticipationId);

  /// The active invitation of [contestParticipationId], or `null`.
  Future<Invitation?> findActiveForParticipation(Id contestParticipationId);

  /// Every invitation of [contestId], oldest first by id.
  Future<List<Invitation>> listForContest(Id contestId);

  /// Stores [invitation], replacing the stored one with the same id. The
  /// database refuses a second active invitation for a participation, a
  /// repeated revision, and a repeated client mutation id.
  /// When the latest invitation of each of [contestIds] was issued, in one
  /// read. A contest with no invitation is absent from the map.
  Future<Map<Id, DateTime>> latestIssuedAtForContests(Iterable<Id> contestIds);

  Future<Invitation> save(Invitation invitation);

  /// Records that [invitationId] was opened by [newRedeemer] at [usedAt], when
  /// its stored redeemer is still [expectedRedeemer] (null for none yet).
  ///
  /// One conditional write that changes only the redeemer and the usage
  /// timestamps (the first use is kept once set), so concurrent opens cannot
  /// overwrite each other or any other field. Returns whether it applied;
  /// false means another open changed the redeemer first, or the invitation
  /// is no longer active.
  Future<bool> redeem(
    Id invitationId, {
    required Id? expectedRedeemer,
    required Id newRedeemer,
    required DateTime usedAt,
  });

  /// Changes only the delivery outcomes of [invitationId]: [change] receives
  /// the stored list and returns the list to keep, or null to keep it as it
  /// is.
  ///
  /// The write replaces nothing else on the invitation, so it cannot undo a
  /// concurrent redemption, and it applies only if the outcomes are still the
  /// ones [change] saw (another writer makes it run again with the new list).
  /// Returns the outcomes now stored, or null when there is no such
  /// invitation.
  ///
  /// With [audit], that event is stored in the same transaction as the
  /// change, and only when the change applies, so a stored change never lacks
  /// its audit event and a failed one leaves none.
  Future<List<Map<String, Object?>>?> updateDeliveryOutcomes(
    Id invitationId,
    List<Map<String, Object?>>? Function(List<Map<String, Object?>> current)
    change, {
    AuditEvent? audit,
  });

  /// Stores every invitation in [invitations] and every event in [audits] in
  /// one transaction: if any write fails, none is kept.
  Future<void> saveIssued(
    List<Invitation> invitations,
    List<AuditEvent> audits,
  );
}
