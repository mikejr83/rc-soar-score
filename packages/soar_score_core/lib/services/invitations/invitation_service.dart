import 'package:logging/logging.dart';

import '../../enums/account_kind.dart';
import '../../enums/admin_lock.dart';
import '../../enums/audit_action.dart';
import '../../enums/audit_outcome.dart';
import '../../enums/authority.dart';
import '../../enums/invitation_audience.dart';
import '../../enums/invitation_state.dart';
import '../../enums/invitation_type.dart';
import '../../enums/lifecycle_state.dart';
import '../../enums/role_type.dart';
import '../../enums/scoring_access.dart';
import '../../errors/contest_state_error.dart';
import '../../errors/entity_not_found_error.dart';
import '../../errors/invitation_access_error.dart';
import '../../models/accounts/account.dart';
import '../../models/contest/contest.dart';
import '../../models/id.dart';
import '../../models/participants/contest_participation.dart';
import '../../models/scores/invitation.dart';
import '../../models/sync/audit_event.dart';
import '../../repositories/repository.dart';
import 'invitation_codec.dart';
import 'participant_access.dart';

final _logger = Logger('Invitations');

/// Issues invitations and turns a link or a guest session into access.
///
/// Rules from `plan/architecture-requirements/self-scoring-invites.md`: one
/// stable, reusable link per participation; issuance only while the contest
/// is Configuring, Ready or Running; every failure to open a link looks the
/// same; the guest session is checked against the stored invitation, the
/// contest lifecycle and scoring access on every request.
///
/// Regenerating and revoking an invitation, helper links and email delivery
/// are not here yet (#141 keeps them open, #790, #791).
class InvitationService {
  InvitationService(
    this.repository,
    this.codec, {
    DateTime Function()? clock,
    Id Function()? newId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? Id.create;

  final Repository repository;
  final InvitationCodec codec;
  final DateTime Function() _clock;
  final Id Function() _newId;

  /// How long after a contest completes its links still open the read-only
  /// overview.
  static const completedGrace = Duration(hours: 24);

  /// How long a guest session token lasts at most. A session also ends with
  /// its invitation; the app reopens the link for a new one.
  static const sessionLifetime = Duration(days: 30);

  /// The active invitation of [participationId], issuing it first when there
  /// is none.
  ///
  /// Idempotent: a retry with the same [clientMutationId], or a second
  /// request for a participation that already has an active invitation,
  /// returns the same link with `created` false.
  Future<IssuedInvitation> issue({
    required Id contestId,
    required Id participationId,
    required Id issuedBy,
    required String clientMutationId,
    InvitationType type = InvitationType.qrCode,
  }) async {
    final contest = await repository.contestRepository.findById(contestId);
    if (contest == null) {
      throw EntityNotFoundError(entityType: 'Contest', entityId: contestId);
    }
    final participation = await repository.contestParticipationRepository
        .findById(participationId);
    if (participation == null || participation.contestId != contestId) {
      throw EntityNotFoundError(
        entityType: 'ContestParticipation',
        entityId: participationId,
      );
    }

    final earlier = await repository.invitationRepository
        .findByClientMutationId(
          contestId: contestId,
          clientMutationId: clientMutationId,
        );
    if (earlier != null) {
      if (earlier.contestParticipationId != participationId) {
        throw ContestStateError(
          'client_mutation_reused',
          'that request id was already used for another participant',
        );
      }
      return _issued(earlier, created: false);
    }

    if (contest.lifecycleState == LifecycleState.created ||
        contest.lifecycleState == LifecycleState.completed) {
      throw ContestStateError(
        'invitations_not_issuable',
        'invitations are issued while a contest is Configuring, Ready or '
            'Running, this one is ${contest.lifecycleState.name}',
      );
    }
    if (participation.roleType != RoleType.pilot) {
      throw ContestStateError(
        'helper_invitations_unavailable',
        'only pilots can be invited so far',
      );
    }

    final existing = await repository.invitationRepository
        .findActiveForParticipation(participationId);
    if (existing != null) return _issued(existing, created: false);

    final all = await repository.invitationRepository.listForParticipation(
      participationId,
    );
    final now = _clock().toUtc();
    final id = _newId();
    final revision = all.isEmpty ? 1 : all.last.invitationRevision + 1;
    final credential = codec.credentialFor(id, revision);
    final Invitation invitation;
    try {
      invitation = await repository.invitationRepository.save(
        Invitation(
          id: id,
          contestId: contestId,
          contestParticipationId: participationId,
          type: type,
          protectedCredential: codec.protect(credential),
          invitationRevision: revision,
          audience: InvitationAudience.pilot,
          issuedBy: issuedBy,
          issuedAt: now,
          replacesInvitationId: null,
          clientMutationId: clientMutationId,
        ),
      );
    } on Object {
      // A concurrent request may have issued first: the database refuses a
      // second active invitation, a repeated revision and a repeated request
      // id. Whoever won is the answer; anything else is a real failure.
      final winner =
          await repository.invitationRepository.findByClientMutationId(
            contestId: contestId,
            clientMutationId: clientMutationId,
          ) ??
          await repository.invitationRepository.findActiveForParticipation(
            participationId,
          );
      if (winner == null ||
          winner.id == id ||
          winner.contestParticipationId != participationId) {
        rethrow;
      }
      return _issued(winner, created: false);
    }
    await _audit(
      invitation,
      AuditAction.invitationIssued,
      actorId: issuedBy,
      authority: Authority.director,
      now: now,
    );
    return IssuedInvitation(
      invitation: invitation,
      credential: credential,
      created: true,
    );
  }

  /// The link of an invitation already issued, for the director to print or
  /// copy.
  IssuedInvitation _issued(Invitation invitation, {required bool created}) =>
      IssuedInvitation(
        invitation: invitation,
        credential: codec.credentialFor(
          invitation.id,
          invitation.invitationRevision,
        ),
        created: created,
      );

  /// The link of [invitation], to print or copy again.
  String credentialOf(Invitation invitation) =>
      codec.credentialFor(invitation.id, invitation.invitationRevision);

  /// Opens [credential]: finds the one invitation, contest and participation
  /// it names, creates the participation's guest account on first use, and
  /// returns the session to keep.
  ///
  /// Throws [InvitationAccessError.invalidLink] for a link that is unknown,
  /// replaced, revoked or expired, always the same way.
  Future<InvitationResolution> resolve(String credential) async {
    final id = codec.idOf(credential);
    final stored = id == null
        ? null
        : await repository.invitationRepository.findById(id);
    if (stored == null ||
        !codec.matches(credential, stored.protectedCredential)) {
      _logger.info('An invitation link did not match any invitation.');
      throw InvitationAccessError.invalidLink();
    }

    final now = _clock().toUtc();
    final checked = await _check(stored, now);
    if (checked == null) {
      await _audit(
        stored,
        AuditAction.invitationAccessFailed,
        authority: Authority.participant,
        now: now,
        outcome: AuditOutcome.rejected,
      );
      throw InvitationAccessError.invalidLink();
    }

    var invitation = stored;
    final guestId =
        stored.redeemedByAccountId ??
        await _guestFor(stored.id, checked.participation, now);
    invitation = await repository.invitationRepository.save(
      Invitation(
        id: stored.id,
        contestId: stored.contestId,
        contestParticipationId: stored.contestParticipationId,
        type: stored.type,
        protectedCredential: stored.protectedCredential,
        invitationRevision: stored.invitationRevision,
        state: stored.state,
        audience: stored.audience,
        issuedBy: stored.issuedBy,
        issuedAt: stored.issuedAt,
        expiresAt: stored.expiresAt,
        firstUsedAt: stored.firstUsedAt ?? now,
        lastUsedAt: now,
        revokedAt: stored.revokedAt,
        replacesInvitationId: stored.replacesInvitationId,
        redeemedByAccountId: guestId,
        deliveryOutcomes: stored.deliveryOutcomes,
        clientMutationId: stored.clientMutationId,
      ),
    );
    await _audit(
      invitation,
      AuditAction.invitationAccessed,
      actorId: guestId,
      authority: Authority.participant,
      now: now,
    );

    final access = ParticipantAccess(
      guestAccountId: guestId,
      invitation: invitation,
      participation: checked.participation,
      contest: checked.contest,
      readOnly: checked.readOnly,
    );
    var sessionEnds = now.add(sessionLifetime);
    if (checked.expiry != null && checked.expiry!.isBefore(sessionEnds)) {
      sessionEnds = checked.expiry!;
    }
    return InvitationResolution(
      access: access,
      sessionExpiresAt: sessionEnds,
      sessionToken: codec.signSession({
        'exp': sessionEnds.millisecondsSinceEpoch ~/ 1000,
        'v': 1,
        'acct': guestId.value,
        'inv': invitation.id.value,
        'rev': invitation.invitationRevision,
        'part': invitation.contestParticipationId.value,
        'contest': invitation.contestId.value,
      }),
    );
  }

  /// Checks a guest session and returns what it opens, as of now.
  ///
  /// Call it on every participant request, with [write] true for one that
  /// changes something: a write also needs the contest Running or Ready with
  /// scoring Open and not locked, and the participant not retired from the
  /// round (the caller checks the round). Throws
  /// [InvitationAccessError.invalidSession] when the token is forged or its
  /// invitation no longer authorizes, and a [ContestStateError] when the
  /// session is good but the contest does not accept scores.
  Future<ParticipantAccess> authorize(
    String sessionToken, {
    bool write = false,
  }) async {
    final claims = codec.verifySession(sessionToken);
    if (claims == null) throw InvitationAccessError.invalidSession();
    final Id invitationId;
    final Id accountId;
    final int revision;
    final now = _clock().toUtc();
    try {
      final exp = claims['exp']! as int;
      if (now.millisecondsSinceEpoch ~/ 1000 >= exp) {
        throw InvitationAccessError.invalidSession();
      }
      invitationId = Id.parse(claims['inv']! as String);
      accountId = Id.parse(claims['acct']! as String);
      revision = claims['rev']! as int;
    } on InvitationAccessError {
      rethrow;
    } on Object {
      throw InvitationAccessError.invalidSession();
    }
    final invitation = await repository.invitationRepository.findById(
      invitationId,
    );
    if (invitation == null ||
        invitation.invitationRevision != revision ||
        invitation.redeemedByAccountId != accountId) {
      throw InvitationAccessError.invalidSession();
    }
    final checked = await _check(invitation, now);
    if (checked == null) throw InvitationAccessError.invalidSession();

    if (write) _requireAcceptsScores(checked.contest, checked.readOnly);
    return ParticipantAccess(
      guestAccountId: accountId,
      invitation: invitation,
      participation: checked.participation,
      contest: checked.contest,
      readOnly: checked.readOnly,
    );
  }

  void _requireAcceptsScores(Contest contest, bool readOnly) {
    if (readOnly || contest.lifecycleState == LifecycleState.completed) {
      throw ContestStateError(
        'scoring_closed',
        'the contest is completed, scores can no longer be submitted',
      );
    }
    if (contest.adminLock == AdminLock.locked) {
      throw ContestStateError(
        'scoring_closed',
        'the director has locked the contest',
      );
    }
    if (contest.scoringAccess != ScoringAccess.open) {
      throw ContestStateError(
        'scoring_closed',
        'the director has not opened participant scoring',
      );
    }
  }

  /// The participation and contest behind [invitation] when it still
  /// authorizes access at [now], else null.
  Future<
    ({
      ContestParticipation participation,
      Contest contest,
      bool readOnly,
      DateTime? expiry,
    })?
  >
  _check(Invitation invitation, DateTime now) async {
    if (invitation.state != InvitationState.active) return null;
    if (invitation.audience != InvitationAudience.pilot) return null;
    final contest = await repository.contestRepository.findById(
      invitation.contestId,
    );
    if (contest == null || contest.lifecycleState == LifecycleState.created) {
      return null;
    }
    final completed = contest.lifecycleState == LifecycleState.completed;
    // The completion time is not kept apart from the contest's last update,
    // which a completed contest stops getting, so it stands in for it.
    final expiry =
        invitation.expiresAt ??
        (completed ? contest.updatedAt.add(completedGrace) : null);
    if (expiry != null && !now.isBefore(expiry)) return null;
    final participation = await repository.contestParticipationRepository
        .findById(invitation.contestParticipationId);
    if (participation == null ||
        participation.contestId != invitation.contestId ||
        participation.roleType != RoleType.pilot) {
      return null;
    }
    return (
      participation: participation,
      contest: contest,
      readOnly: completed,
      expiry: expiry,
    );
  }

  /// The guest account of [invitationId], made if it is not there yet.
  ///
  /// Its id comes from the invitation (see [InvitationCodec.guestAccountIdFor]),
  /// so concurrent first opens all make and agree on the same account.
  Future<Id> _guestFor(
    Id invitationId,
    ContestParticipation participation,
    DateTime now,
  ) async {
    final id = codec.guestAccountIdFor(invitationId);
    if (await repository.accountRepository.findById(id) != null) return id;
    final profile = await repository.participantProfileRepository.findById(
      participation.participantProfileId,
    );
    await repository.accountRepository.save(
      Account(
        id: id,
        firstName: profile?.firstName ?? 'Guest',
        lastName: profile?.lastName ?? 'Pilot',
        kind: AccountKind.guest,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  Future<void> _audit(
    Invitation invitation,
    AuditAction action, {
    Id? actorId,
    required Authority authority,
    required DateTime now,
    AuditOutcome outcome = AuditOutcome.success,
  }) => repository.auditEventRepository.append(
    AuditEvent(
      id: _newId(),
      entityType: 'Invitation',
      entityId: invitation.id,
      contestId: invitation.contestId,
      action: action,
      actorId: actorId,
      authority: authority,
      resultingRevision: invitation.invitationRevision,
      serverTimestamp: now,
      outcome: outcome,
    ),
  );
}
