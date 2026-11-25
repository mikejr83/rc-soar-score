import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';

/// A [Repository] whose invitation redemptions and link claims can be paused
/// by a test, to place two requests exactly where a race would.
///
/// Everything else is the real database. [afterRedeem] runs after a
/// conditional redemption has been written; [beforeClaim] runs before a
/// guest claim is written and [afterClaim] after it was.
class GatedRepository extends Repository {
  GatedRepository(super.db);

  Future<void> Function(core.Id newRedeemer, bool applied)? afterRedeem;
  Future<void> Function()? beforeClaim;
  void Function()? afterClaim;

  late final _invitations = _GatedInvitations(super.invitationRepository, this);
  late final _links = _GatedLinks(super.participantAccountLinkRepository, this);

  @override
  core.InvitationRepository get invitationRepository => _invitations;

  @override
  core.ParticipantAccountLinkRepository get participantAccountLinkRepository =>
      _links;
}

class _GatedInvitations implements core.InvitationRepository {
  _GatedInvitations(this._real, this._gate);

  final core.InvitationRepository _real;
  final GatedRepository _gate;

  @override
  Future<bool> redeem(
    core.Id invitationId, {
    required core.Id? expectedRedeemer,
    required core.Id newRedeemer,
    required DateTime usedAt,
  }) async {
    final applied = await _real.redeem(
      invitationId,
      expectedRedeemer: expectedRedeemer,
      newRedeemer: newRedeemer,
      usedAt: usedAt,
    );
    await _gate.afterRedeem?.call(newRedeemer, applied);
    return applied;
  }

  @override
  Future<core.Invitation?> findById(core.Id id) => _real.findById(id);

  @override
  Future<core.Invitation?> findByClientMutationId({
    required core.Id contestId,
    required String clientMutationId,
  }) => _real.findByClientMutationId(
    contestId: contestId,
    clientMutationId: clientMutationId,
  );

  @override
  Future<core.Invitation?> findByProtectedCredential(String credential) =>
      _real.findByProtectedCredential(credential);

  @override
  Future<List<core.Invitation>> listForParticipation(
    core.Id contestParticipationId,
  ) => _real.listForParticipation(contestParticipationId);

  @override
  Future<List<core.Invitation>> listForParticipations(
    Iterable<core.Id> contestParticipationIds,
  ) => _real.listForParticipations(contestParticipationIds);

  @override
  Future<core.Invitation?> findActiveForParticipation(
    core.Id contestParticipationId,
  ) => _real.findActiveForParticipation(contestParticipationId);

  @override
  Future<List<core.Invitation>> listForContest(core.Id contestId) =>
      _real.listForContest(contestId);

  @override
  Future<Map<core.Id, DateTime>> latestIssuedAtForContests(
    Iterable<core.Id> contestIds,
  ) => _real.latestIssuedAtForContests(contestIds);

  @override
  Future<core.Invitation> save(core.Invitation invitation) =>
      _real.save(invitation);

  @override
  Future<void> saveIssued(
    List<core.Invitation> invitations,
    List<core.AuditEvent> audits,
  ) => _real.saveIssued(invitations, audits);
}

class _GatedLinks implements core.ParticipantAccountLinkRepository {
  _GatedLinks(this._real, this._gate);

  final core.ParticipantAccountLinkRepository _real;
  final GatedRepository _gate;

  Future<T> _claiming<T>(Future<T> Function() claim) async {
    await _gate.beforeClaim?.call();
    final result = await claim();
    _gate.afterClaim?.call();
    return result;
  }

  @override
  Future<bool> claimGuests(
    core.ParticipantAccountLink link, {
    required Iterable<core.Id> guestAccountIds,
  }) => _claiming(
    () => _real.claimGuests(link, guestAccountIds: guestAccountIds),
  );

  @override
  Future<core.ParticipantAccountLink> saveClaimingGuests(
    core.ParticipantAccountLink link, {
    required Iterable<core.Id> guestAccountIds,
  }) => _claiming(
    () => _real.saveClaimingGuests(link, guestAccountIds: guestAccountIds),
  );

  @override
  Future<core.ParticipantAccountLink?> findById(core.Id id) =>
      _real.findById(id);

  @override
  Future<core.ParticipantAccountLink?> find({
    required core.Id participantProfileId,
    required core.Id accountId,
  }) => _real.find(
    participantProfileId: participantProfileId,
    accountId: accountId,
  );

  @override
  Future<core.ParticipantAccountLink?> findConfirmedForProfile(
    core.Id participantProfileId,
  ) => _real.findConfirmedForProfile(participantProfileId);

  @override
  Future<List<core.ParticipantAccountLink>> listForProfile(
    core.Id participantProfileId,
  ) => _real.listForProfile(participantProfileId);

  @override
  Future<List<core.ParticipantAccountLink>> listForAccount(core.Id accountId) =>
      _real.listForAccount(accountId);

  @override
  Future<List<core.ParticipantAccountLink>> listForProfiles(
    Iterable<core.Id> participantProfileIds,
  ) => _real.listForProfiles(participantProfileIds);

  @override
  Future<core.ParticipantAccountLink> saveReleasingInvitations(
    core.ParticipantAccountLink link, {
    required Map<core.Id, core.Id?> invitationToGuest,
  }) => _real.saveReleasingInvitations(
    link,
    invitationToGuest: invitationToGuest,
  );

  @override
  Future<core.ParticipantAccountLink> save(core.ParticipantAccountLink link) =>
      _real.save(link);
}
