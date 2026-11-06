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

  /// Stores every invitation in [invitations] and every event in [audits] in
  /// one transaction: if any write fails, none is kept.
  Future<void> saveIssued(
    List<Invitation> invitations,
    List<AuditEvent> audits,
  );
}
