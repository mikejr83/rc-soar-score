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

  /// The current time as this service reads it, so services built on it (the
  /// participant links) agree with it, including a clock a test moves.
  DateTime now() => _clock();

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

    final existing = await repository.invitationRepository
        .findActiveForParticipation(participationId);
    if (existing != null) return _issued(existing, created: false);

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

  /// Whether invitations can be issued for [contest] now, and the reason
  /// (a stable code with text) when they cannot.
  ///
  /// Issuance is open while a contest is Configuring, Ready or Running.
  ({bool canIssue, String? code, String? reason}) issuability(Contest contest) {
    switch (contest.lifecycleState) {
      case LifecycleState.created:
      case LifecycleState.completed:
        return (
          canIssue: false,
          code: 'invitations_not_issuable',
          reason:
              'invitations are issued while a contest is Configuring, Ready '
              'or Running, this one is ${contest.lifecycleState.name}',
        );
      default:
        return (canIssue: true, code: null, reason: null);
    }
  }

  /// The active invitation of each participation of [contestId] that has
  /// one, with the credential to print or copy.
  ///
  /// An invitation whose link cannot be reproduced (the server's secret
  /// changed since it was issued, so the recomputed credential no longer
  /// matches the stored hash) is listed in [unreproducible] instead, never
  /// with a link that would not open.
  Future<({List<IssuedInvitation> links, List<Id> unreproducible})>
  activeForContest(Id contestId) async {
    final all = await repository.invitationRepository.listForContest(contestId);
    final links = <IssuedInvitation>[];
    final unreproducible = <Id>[];
    for (final invitation in all) {
      if (invitation.state != InvitationState.active) continue;
      if (_reproducible(invitation)) {
        links.add(_issued(invitation, created: false));
      } else {
        unreproducible.add(invitation.contestParticipationId);
      }
    }
    return (links: links, unreproducible: unreproducible);
  }

  bool _reproducible(Invitation invitation) => codec.matches(
    codec.credentialFor(invitation.id, invitation.invitationRevision),
    invitation.protectedCredential,
  );

  /// Issues an invitation for each of [participationIds] that has none, as
  /// one request: everything is checked first, so a request that cannot
  /// complete issues nothing. Participations that already have an invitation
  /// come back with the same link and `created` false, so a repeat or a
  /// reprint changes nothing. Never sends email.
  ///
  /// Each participation's idempotency key is [requestId] with the
  /// participation id, so a retry of the same request finds what it issued.
  Future<List<IssuedInvitation>> issueMany({
    required Id contestId,
    required List<Id> participationIds,
    required Id issuedBy,
    required String requestId,
  }) async {
    final contest = await repository.contestRepository.findById(contestId);
    if (contest == null) {
      throw EntityNotFoundError(entityType: 'Contest', entityId: contestId);
    }
    final unique = participationIds.toSet().toList();
    final participations = <Id, ContestParticipation>{};
    for (final id in unique) {
      final participation = await repository.contestParticipationRepository
          .findById(id);
      if (participation == null || participation.contestId != contestId) {
        throw EntityNotFoundError(
          entityType: 'ContestParticipation',
          entityId: id,
        );
      }
      participations[id] = participation;
    }
    final needNew = <Id>[
      for (final id in unique)
        if (await repository.invitationRepository.findActiveForParticipation(
              id,
            ) ==
            null)
          id,
    ];
    if (needNew.isNotEmpty) {
      final check = issuability(contest);
      if (!check.canIssue) {
        throw ContestStateError(check.code!, check.reason!);
      }
      for (final id in needNew) {
        if (participations[id]!.roleType != RoleType.pilot) {
          throw ContestStateError(
            'helper_invitations_unavailable',
            'only pilots can be invited so far',
          );
        }
      }
    }
    // Prepare everything first, then store all the new invitations and their
    // audit events in one transaction: a failure leaves nothing issued.
    final now = _clock().toUtc();
    final answers = <Id, IssuedInvitation>{};
    final fresh = <IssuedInvitation>[];
    final audits = <AuditEvent>[];
    for (final id in unique) {
      final mutation = '$requestId/${id.value}';
      final earlier = await repository.invitationRepository
          .findByClientMutationId(
            contestId: contestId,
            clientMutationId: mutation,
          );
      if (earlier != null) {
        if (earlier.contestParticipationId != id) {
          throw ContestStateError(
            'client_mutation_reused',
            'that request id was already used for another participant',
          );
        }
        answers[id] = _issued(earlier, created: false);
        continue;
      }
      final existing = await repository.invitationRepository
          .findActiveForParticipation(id);
      if (existing != null) {
        answers[id] = _issued(existing, created: false);
        continue;
      }
      final history = await repository.invitationRepository
          .listForParticipation(id);
      final invitationId = _newId();
      final revision = history.isEmpty
          ? 1
          : history.last.invitationRevision + 1;
      final credential = codec.credentialFor(invitationId, revision);
      final invitation = Invitation(
        id: invitationId,
        contestId: contestId,
        contestParticipationId: id,
        type: InvitationType.qrCode,
        protectedCredential: codec.protect(credential),
        invitationRevision: revision,
        audience: InvitationAudience.pilot,
        issuedBy: issuedBy,
        issuedAt: now,
        replacesInvitationId: null,
        clientMutationId: mutation,
      );
      final issued = IssuedInvitation(
        invitation: invitation,
        credential: credential,
        created: true,
      );
      answers[id] = issued;
      fresh.add(issued);
      audits.add(
        _auditEvent(
          invitation,
          AuditAction.invitationIssued,
          actorId: issuedBy,
          authority: Authority.director,
          now: now,
        ),
      );
    }
    if (fresh.isNotEmpty) {
      try {
        await repository.invitationRepository.saveIssued([
          for (final f in fresh) f.invitation,
        ], audits);
      } on Object {
        // A concurrent request may have issued first. If every pilot now has
        // an invitation, whoever won is the answer; anything else is a real
        // failure of this request.
        final winners = <Id, IssuedInvitation>{};
        for (final id in unique) {
          final active = await repository.invitationRepository
              .findActiveForParticipation(id);
          if (active == null) rethrow;
          winners[id] = _issued(active, created: false);
        }
        return [for (final id in unique) winners[id]!];
      }
    }
    return [for (final id in unique) answers[id]!];
  }

  /// The link of an invitation already issued, for the director to print or
  /// copy.
  ///
  /// Throws a [ContestStateError] (`invitation_link_unavailable`) when the
  /// link cannot be reproduced because the server's secret changed.
  IssuedInvitation _issued(Invitation invitation, {required bool created}) {
    if (!_reproducible(invitation)) {
      throw ContestStateError(
        'invitation_link_unavailable',
        'the invitation secret changed after this invitation was issued, so '
            'its link cannot be reproduced; regenerating it is not available '
            'yet (#791)',
      );
    }
    return IssuedInvitation(
      invitation: invitation,
      credential: codec.credentialFor(
        invitation.id,
        invitation.invitationRevision,
      ),
      created: created,
    );
  }

  /// The credential of the invitation a verified guest session was opened
  /// with, for the participant to copy their own link.
  ///
  /// Throws a [ContestStateError] (`invitation_link_unavailable`) when the
  /// link cannot be reproduced because the server's secret changed.
  String credentialForAccess(ParticipantAccess access) =>
      _issued(access.invitation, created: false).credential;

  /// The link of [invitation], to print or copy again.
  String credentialOf(Invitation invitation) =>
      codec.credentialFor(invitation.id, invitation.invitationRevision);

  /// Finds the invitation [credential] names and checks that it opens now,
  /// without redeeming it: no guest account is made and nothing is stored on
  /// success.
  ///
  /// A failure is [InvitationAccessError.invalidLink], logged and audited
  /// (the failed attempt is stored as an audit event) exactly as [resolve] does, so an account that submits a link learns no
  /// more than an anonymous visitor.
  Future<OpenedInvitation> lookup(String credential) async {
    final opened = await _open(credential);
    return OpenedInvitation(
      invitation: opened.invitation,
      participation: opened.checked.participation,
      contest: opened.checked.contest,
      readOnly: opened.checked.readOnly,
    );
  }

  Future<
    ({
      Invitation invitation,
      DateTime now,
      ({
        ContestParticipation participation,
        Contest contest,
        bool readOnly,
        DateTime? expiry,
      })
      checked,
    })
  >
  _open(String credential) async {
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
    return (invitation: stored, now: now, checked: checked);
  }

  /// Opens [credential]: finds the one invitation, contest and participation
  /// it names, creates the participation's guest account on first use, and
  /// returns the session to keep, acting as that guest.
  ///
  /// Opening anonymously never acts as a registered account, even when an
  /// account has claimed the link: the redeemer moves back to the guest, and
  /// the account's next open claims the guest's entries again.
  ///
  /// Throws [InvitationAccessError.invalidLink] for a link that is unknown,
  /// replaced, revoked or expired, always the same way.
  Future<InvitationResolution> resolve(String credential) async {
    final opened = await _open(credential);
    var stored = opened.invitation;
    final guest = await _guestFor(
      stored.id,
      opened.checked.participation,
      opened.now,
    );
    for (var attempt = 0; attempt < 3; attempt++) {
      final session = await _session(
        stored,
        opened.checked,
        opened.now,
        actorId: guest,
      );
      if (session != null) return session;
      // A concurrent open changed the redeemer first: read it again, when
      // another attempt follows.
      if (attempt == 2) break;
      final latest = await repository.invitationRepository.findById(stored.id);
      if (latest == null) break;
      stored = latest;
    }
    throw InvitationAccessError.invalidLink();
  }

  /// Opens [invitation] for the signed-in, linked [accountId]: the same
  /// session [resolve] gives a guest, acting as the account.
  ///
  /// The caller (the participant link service) has already confirmed the
  /// account's link to the invitation's profile and claimed the guests'
  /// entries. The invitation is stored as redeemed by the account when
  /// nobody has opened it yet.
  ///
  /// Returns null when a guest opened the invitation in the meantime (it is
  /// redeemed by another account): the caller claims that guest and calls
  /// again. Throws [InvitationAccessError.invalidLink] when [invitation] no
  /// longer opens, exactly like [resolve].
  Future<InvitationResolution?> resolveForAccount(
    Invitation invitation,
    Id accountId,
  ) async {
    final now = _clock().toUtc();
    // Read again: the row the caller holds may be older than a guest's open.
    final stored = await repository.invitationRepository.findById(
      invitation.id,
    );
    final checked = stored == null ? null : await _check(stored, now);
    if (stored == null || checked == null) {
      if (stored != null) {
        await _audit(
          stored,
          AuditAction.invitationAccessFailed,
          authority: Authority.participant,
          now: now,
          outcome: AuditOutcome.rejected,
        );
      }
      throw InvitationAccessError.invalidLink();
    }
    final redeemer = stored.redeemedByAccountId;
    if (redeemer != null && redeemer != accountId) return null;
    // The write also needs the account's Confirmed link, so an unlink that
    // lands first leaves the invitation with its guest.
    return _session(
      stored,
      checked,
      now,
      actorId: accountId,
      requireConfirmedLink: true,
    );
  }

  /// Stores that [stored] was opened by [actorId] and returns the session, or
  /// null when a concurrent open changed the redeemer meanwhile.
  ///
  /// The write is one conditional update on the redeemer that was read
  /// ([InvitationRepository.redeem]), so it changes nothing else and two opens
  /// cannot both win. A successful update is the answer; only a failed one
  /// makes the caller re-read and decide who to act as.
  Future<InvitationResolution?> _session(
    Invitation stored,
    ({
      ContestParticipation participation,
      Contest contest,
      bool readOnly,
      DateTime? expiry,
    })
    checked,
    DateTime now, {
    required Id actorId,
    bool requireConfirmedLink = false,
  }) async {
    final applied = await repository.invitationRepository.redeem(
      stored.id,
      expectedRedeemer: stored.redeemedByAccountId,
      newRedeemer: actorId,
      usedAt: now,
      requireConfirmedLinkOf: requireConfirmedLink
          ? (
              profileId: checked.participation.participantProfileId,
              accountId: actorId,
            )
          : null,
    );
    if (!applied) return null;
    // Built from the write that applied, not read back: a read could see a
    // later open and make this one look lost although its update succeeded.
    final invitation = Invitation(
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
      redeemedByAccountId: actorId,
      deliveryOutcomes: stored.deliveryOutcomes,
      clientMutationId: stored.clientMutationId,
    );
    await _audit(
      invitation,
      AuditAction.invitationAccessed,
      actorId: actorId,
      authority: Authority.participant,
      now: now,
    );

    final access = ParticipantAccess(
      guestAccountId: actorId,
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
        'acct': actorId.value,
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

    // A session of a signed-in account (not the invitation's own guest) is
    // good only while the account still holds the Confirmed link to the
    // pilot, checked on every request: unlinking ends it at once.
    if (accountId != codec.guestAccountIdFor(invitation.id)) {
      final link = await repository.participantAccountLinkRepository.find(
        participantProfileId: checked.participation.participantProfileId,
        accountId: accountId,
      );
      if (link == null || !link.isConfirmed) {
        throw InvitationAccessError.invalidSession();
      }
    }

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
    // Cheap refusals first, so no read is made for an invitation that cannot
    // authorize.
    if (invitation.state != InvitationState.active ||
        invitation.audience != InvitationAudience.pilot) {
      return null;
    }
    final contest = await repository.contestRepository.findById(
      invitation.contestId,
    );
    final participation = await repository.contestParticipationRepository
        .findById(invitation.contestParticipationId);
    if (contest == null || participation == null) return null;
    final opens = opening(invitation, contest, participation, now);
    if (opens == null) return null;
    return (
      participation: participation,
      contest: contest,
      readOnly: opens.readOnly,
      expiry: opens.expiry,
    );
  }

  /// Whether [invitation] authorizes access at [now] for [contest] and
  /// [participation], the rows it names: the one rule behind every check, so
  /// a list of many invitations can apply it to rows read in bulk.
  ///
  /// Returns null when it does not authorize. An active, pilot-audience
  /// invitation opens while its contest is past Created, until the invitation
  /// expires or [completedGrace] after the contest completed; `readOnly` is
  /// true once the contest is completed.
  static ({bool readOnly, DateTime? expiry})? opening(
    Invitation invitation,
    Contest contest,
    ContestParticipation participation,
    DateTime now,
  ) {
    if (invitation.state != InvitationState.active) return null;
    if (invitation.audience != InvitationAudience.pilot) return null;
    if (contest.id != invitation.contestId ||
        contest.lifecycleState == LifecycleState.created) {
      return null;
    }
    final completed = contest.lifecycleState == LifecycleState.completed;
    // The completion time is not kept apart from the contest's last update,
    // which a completed contest stops getting, so it stands in for it.
    final expiry =
        invitation.expiresAt ??
        (completed ? contest.updatedAt.add(completedGrace) : null);
    if (expiry != null && !now.isBefore(expiry)) return null;
    if (participation.id != invitation.contestParticipationId ||
        participation.contestId != invitation.contestId ||
        participation.roleType != RoleType.pilot) {
      return null;
    }
    return (readOnly: completed, expiry: expiry);
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
    _auditEvent(
      invitation,
      action,
      actorId: actorId,
      authority: authority,
      now: now,
      outcome: outcome,
    ),
  );

  AuditEvent _auditEvent(
    Invitation invitation,
    AuditAction action, {
    Id? actorId,
    required Authority authority,
    required DateTime now,
    AuditOutcome outcome = AuditOutcome.success,
  }) => AuditEvent(
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
  );
}
