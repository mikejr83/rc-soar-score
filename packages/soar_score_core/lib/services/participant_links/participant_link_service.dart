import 'package:logging/logging.dart';

import '../../enums/account_kind.dart';
import '../../enums/account_status.dart';
import '../../enums/lifecycle_state.dart';
import '../../enums/participant_link_origin.dart';
import '../../enums/participant_link_status.dart';
import '../../enums/role_type.dart';
import '../../errors/invitation_access_error.dart';
import '../../errors/participant_link_error.dart';
import '../../models/accounts/account.dart';
import '../../models/accounts/participant_account_link.dart';
import '../../models/contest/contest.dart';
import '../../models/id.dart';
import '../../models/participants/contest_participation.dart';
import '../../models/scores/invitation.dart';
import '../../repositories/repository.dart';
import '../invitations/invitation_service.dart';
import '../invitations/participant_access.dart';
import 'linked_participation.dart';

final _logger = Logger('ParticipantLinks');

/// Links a pilot's account to a director's participant profile, and hands
/// the account what that gives access to.
///
/// Rules from the participants-and-accounts decision (2026-10-28) and
/// `plan/architecture-requirements/data/accounts.md`:
///
/// - Three ways in: a director copies the pilot from the directory
///   ([linkFromDirectory]), the pilot opens an invitation while signed in
///   ([linkFromInvitation]), or the pilot confirms an email match
///   ([candidatesFor], [confirmCandidate]). The first two are Confirmed at
///   once; the third only when the pilot says so.
/// - A profile has one Confirmed link. A second account is refused with
///   `already_linked`, whichever way it came.
/// - Confirming a link and claiming what the pilot's guest accounts hold
///   (their score attempts, the invitations they opened) is one transaction:
///   there is never a Confirmed link with unclaimed guest entries, nor
///   claimed entries without the link.
/// - Every operation is idempotent. Reads never write and use stored data
///   only. Nothing here changes a profile, a participation or anything
///   published, and nothing reveals to a director that an account exists.
/// - Candidates are computed on read. A row is written only when the pilot
///   acts, so a declined or ended match is never offered again.
///
/// Logs carry ids, never an email or a credential.
class ParticipantLinkService {
  ParticipantLinkService(
    this.repository,
    this.invitations, {
    DateTime Function()? clock,
    Id Function()? newId,
  }) : _clock = clock ?? invitations.now,
       _newId = newId ?? Id.create;

  final Repository repository;
  final InvitationService invitations;
  final DateTime Function() _clock;
  final Id Function() _newId;

  /// Links [accountId] to [profileId] because a director copied the pilot
  /// from the directory: listing there is the pilot's consent, so the link is
  /// Confirmed at once. [directorAccountId] is the director who copies.
  ///
  /// The profile may not have reached the server yet (the director's app
  /// syncs later), so it need not exist. When it does, it must belong to
  /// [directorAccountId] (`profile_not_owned` otherwise). Throws
  /// `already_linked` when another account holds the profile, and
  /// `link_not_found` when [accountId] is not an active registered account
  /// with a listed directory entry.
  /// Repeating it returns the same link.
  Future<ParticipantAccountLink> linkFromDirectory({
    required Id profileId,
    required Id accountId,
    required Id directorAccountId,
  }) async {
    await _requireLinkable(accountId);
    // Listing in the directory is the pilot's consent; an unlisted pilot is
    // refused with the same answer as an unknown one.
    final entry = await repository.participantDirectoryEntryRepository
        .findForAccount(accountId);
    if (entry == null || !entry.isListed) {
      throw ParticipantLinkError.linkNotFound();
    }
    final profile = await repository.participantProfileRepository.findById(
      profileId,
    );
    if (profile != null && profile.ownerAccountId != directorAccountId) {
      throw ParticipantLinkError.profileNotOwned();
    }
    return _confirm(
      profileId: profileId,
      accountId: accountId,
      origin: ParticipantLinkOrigin.directoryPull,
    );
  }

  /// Links [accountId] to the profile behind the invitation [credential]:
  /// the director's invitation identifies the pilot, so the link is
  /// Confirmed at once and claims the entries of the guests of the profile.
  ///
  /// Throws `invalid_invitation` (an `InvitationAccessError`) for a link
  /// that does not open, exactly as opening it anonymously does, and
  /// `already_linked` when another account holds the profile.
  Future<ParticipantAccountLink> linkFromInvitation({
    required String credential,
    required Id accountId,
  }) async {
    await _requireLinkable(accountId);
    final opened = await invitations.lookup(credential);
    return _confirm(
      profileId: opened.participation.participantProfileId,
      accountId: accountId,
      origin: ParticipantLinkOrigin.invitationRedemption,
    );
  }

  /// The pilot, signed in, opens the invitation [credential]: the link is
  /// confirmed (as [linkFromInvitation]) and the guest entries are claimed,
  /// in one transaction, and the answer is the session to keep, acting as
  /// the account, as [InvitationService.resolve] gives a guest.
  ///
  /// Throws `invalid_invitation` for a link that does not open (the same
  /// answer as opening it anonymously) and `already_linked` when another
  /// account holds the profile. Repeating it returns a new session for the
  /// same link and changes nothing else.
  Future<({ParticipantAccountLink link, InvitationResolution session})>
  claimInvitation({required String credential, required Id accountId}) async {
    await _requireLinkable(accountId);
    final opened = await invitations.lookup(credential);
    final profileId = opened.participation.participantProfileId;
    final link = await _confirm(
      profileId: profileId,
      accountId: accountId,
      origin: ParticipantLinkOrigin.invitationRedemption,
    );
    return (
      link: link,
      session: await _openAs(opened.invitation, profileId, accountId),
    );
  }

  /// The pilot opens one of the contests of their list: the session for the
  /// active invitation of [participationId], acting as the account.
  ///
  /// `link_not_found` unless the account holds the Confirmed link to the
  /// participation's profile and the participation is on its list (an
  /// invitation that still opens): the same answer for an id that does not
  /// exist, so it is no way to probe for participations.
  Future<InvitationResolution> openParticipation({
    required Id participationId,
    required Id accountId,
  }) async {
    final participation = await repository.contestParticipationRepository
        .findById(participationId);
    if (participation == null || participation.roleType != RoleType.pilot) {
      throw ParticipantLinkError.linkNotFound();
    }
    final profileId = participation.participantProfileId;
    final link = await repository.participantAccountLinkRepository
        .findConfirmedForProfile(profileId);
    if (link == null || link.accountId != accountId) {
      throw ParticipantLinkError.linkNotFound();
    }
    final listed = (await _openParticipations({profileId}))[profileId] ?? [];
    final row = listed
        .where((r) => r.participation.id == participationId)
        .firstOrNull;
    if (row == null) throw ParticipantLinkError.linkNotFound();
    // Claims the guests who opened this or an earlier invitation of the
    // profile since the link was made, so the session sees all their entries.
    await _confirm(
      profileId: profileId,
      accountId: accountId,
      origin: link.origin,
    );
    return _openAs(row.invitation, profileId, accountId);
  }

  /// Opens [invitation] as [accountId]. A guest that opened it after the
  /// link was confirmed is claimed first (once), so no guest entry stays
  /// behind.
  Future<InvitationResolution> _openAs(
    Invitation invitation,
    Id profileId,
    Id accountId,
  ) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final session = await invitations.resolveForAccount(
        invitation,
        accountId,
      );
      if (session != null) return session;
      // Claim the guest only when another attempt follows: a claim after the
      // last attempt would end whatever session that guest holds and still
      // leave the caller without one.
      if (attempt == 0) {
        await _confirm(
          profileId: profileId,
          accountId: accountId,
          origin: ParticipantLinkOrigin.invitationRedemption,
        );
      }
    }
    // Something else keeps redeeming it: do not guess, refuse like a link
    // that does not open.
    throw InvitationAccessError.invalidLink();
  }

  /// The profiles that match [accountId]'s verified email and that a
  /// director has invited to a contest that still opens, for "Is this you?".
  ///
  /// Empty unless the account is an active registered account with a
  /// verified email. Skips profiles that already have a Confirmed link (to
  /// anyone) and profiles this account has a link row for, so a match the
  /// pilot declined or ended is not offered again. Only the caller's own
  /// email is ever looked up, so it is no way to find out who is listed.
  Future<List<LinkCandidate>> candidatesFor(Id accountId) async => [
    for (final match in await _matching(accountId))
      if (!match.confirmedElsewhere && match.own == null) match.candidate,
  ];

  /// The profile behind the candidate [candidateId] of [accountId] (see
  /// [LinkCandidate.id]), among the account's email matches right now.
  /// `link_not_found` for any other id.
  Future<Id> profileOfCandidate({
    required Id candidateId,
    required Id accountId,
  }) async {
    for (final match in await _matching(accountId)) {
      if (match.candidate.id == candidateId) return match.candidate.profileId;
    }
    throw ParticipantLinkError.linkNotFound();
  }

  /// The pilot says a candidate is them: Confirmed, and the guest entries of
  /// the profile are claimed, in one transaction.
  ///
  /// The match is checked again now, so a stale or guessed [profileId] is
  /// `link_not_found`, the same answer as for a profile that never matched.
  /// Throws `already_linked` when another account confirmed first. Repeating
  /// it returns the stored link, after claiming the entries of any guest that
  /// has opened an invitation of the profile since.
  Future<ParticipantAccountLink> confirmCandidate({
    required Id profileId,
    required Id accountId,
  }) async {
    final match = await _matchOf(profileId, accountId);
    final own = match.own;
    if (own != null) {
      if (!own.isConfirmed) throw ParticipantLinkError.linkNotFound();
      // A repeat: no change to the link, but any late guest is claimed.
      return _confirm(
        profileId: profileId,
        accountId: accountId,
        origin: own.origin,
      );
    }
    if (match.confirmedElsewhere) throw ParticipantLinkError.alreadyLinked();
    return _confirm(
      profileId: profileId,
      accountId: accountId,
      origin: ParticipantLinkOrigin.emailMatch,
    );
  }

  /// The pilot says a candidate is not them: an Ended row records it, so the
  /// match is not offered again. Repeating it changes nothing.
  ///
  /// `link_not_found` unless the profile is a candidate right now (or the
  /// pilot already declined it).
  Future<void> declineCandidate({
    required Id profileId,
    required Id accountId,
  }) async {
    final match = await _matchOf(profileId, accountId);
    final own = match.own;
    if (own != null) {
      if (own.status == ParticipantLinkStatus.ended) return;
      throw ParticipantLinkError.linkNotFound();
    }
    // Declining is allowed even when another account holds the profile: it
    // only records that this pilot said no.
    final now = _clock().toUtc();
    try {
      await repository.participantAccountLinkRepository.save(
        ParticipantAccountLink(
          id: _newId(),
          participantProfileId: profileId,
          accountId: accountId,
          status: ParticipantLinkStatus.ended,
          origin: ParticipantLinkOrigin.emailMatch,
          createdAt: now,
          endedAt: now,
        ),
      );
    } on Object {
      // A concurrent decline stored the same pair first: whoever won is the
      // answer. Anything else is a real failure.
      final winner = await repository.participantAccountLinkRepository.find(
        participantProfileId: profileId,
        accountId: accountId,
      );
      if (winner == null) rethrow;
    }
    _logger.info('Link candidate declined for account ${accountId.value}.');
  }

  /// Ends [accountId]'s Confirmed link [linkId]. The invitations the account
  /// holds for the profile's participations go back to the guest accounts
  /// they came from (or to nobody, when no guest ever held them), in the same
  /// transaction, so an anonymous holder of the link keeps working. The
  /// account's score attempts stay its own, and nothing published changes.
  ///
  /// `link_not_found` when the link is not the account's. Ending an Ended
  /// link changes nothing.
  Future<ParticipantAccountLink> end({
    required Id linkId,
    required Id accountId,
  }) async {
    final links = repository.participantAccountLinkRepository;
    final link = await links.findById(linkId);
    if (link == null || link.accountId != accountId) {
      throw ParticipantLinkError.linkNotFound();
    }
    if (link.status == ParticipantLinkStatus.ended) return link;
    if (link.status == ParticipantLinkStatus.candidate) {
      throw ParticipantLinkError.linkNotFound();
    }
    final held = await _invitationsOf(link.participantProfileId);
    final release = <Id, Id?>{};
    for (final invitation in held) {
      if (invitation.redeemedByAccountId != accountId) continue;
      final guest = invitations.codec.guestAccountIdFor(invitation.id);
      final exists = await repository.accountRepository.findById(guest) != null;
      release[invitation.id] = exists ? guest : null;
    }
    final ended = await links.saveReleasingInvitations(
      _ended(link),
      invitationToGuest: release,
    );
    _logger.info('Link ${ended.id.value} ended.');
    return ended;
  }

  /// The Confirmed links of [accountId], oldest first.
  Future<List<ParticipantAccountLink>> confirmedLinksFor(Id accountId) async =>
      [
        for (final link
            in await repository.participantAccountLinkRepository.listForAccount(
              accountId,
            ))
          if (link.isConfirmed) link,
      ];

  /// The participations [accountId] reaches: every pilot participation of
  /// every profile it holds a Confirmed link to, with an active invitation
  /// that still opens (so a completed contest drops off 24 hours after it
  /// completed). A later invitation of a linked profile appears with no
  /// further confirmation.
  ///
  /// Stored data only, in a few bulk reads however many links there are.
  /// Ordered by contest start, newest first.
  Future<List<LinkedParticipation>> participationsFor(Id accountId) async {
    final links = await confirmedLinksFor(accountId);
    if (links.isEmpty) return const [];
    final reachable = await _openParticipations({
      for (final link in links) link.participantProfileId,
    });
    final rows = <LinkedParticipation>[
      for (final link in links)
        for (final row in reachable[link.participantProfileId] ?? const [])
          LinkedParticipation(
            link: link,
            participation: row.participation,
            contest: row.contest,
            invitation: row.invitation,
            readOnly: row.readOnly,
          ),
    ];
    rows.sort((a, b) {
      final byStart = b.contest.startDateTime.compareTo(
        a.contest.startDateTime,
      );
      return byStart != 0
          ? byStart
          : a.participationId.value.compareTo(b.participationId.value);
    });
    return rows;
  }

  /// The finished contests [accountId] took part in as a pilot through its
  /// Confirmed links: the history that starts where [participationsFor]
  /// leaves off, [InvitationService.completedGrace] after a contest completed.
  ///
  /// A contest is here exactly when it is finished and no invitation of the
  /// pilot opens it any more, so this list and [participationsFor] never
  /// overlap. Nothing is needed once it leaves: history outlives invitations.
  /// A contest reached only through an ended link is not listed; linking
  /// again brings it back.
  /// Ordered by contest start, newest first, then [offset] rows skipped and
  /// at most [limit] returned; [hasMore] says whether more follow.
  ///
  /// Stored data only, in a few bulk reads however many links there are.
  Future<({List<PastParticipation> rows, bool hasMore})> historyFor(
    Id accountId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final links = await confirmedLinksFor(accountId);
    if (links.isEmpty) {
      return (rows: const <PastParticipation>[], hasMore: false);
    }
    final linkOf = {for (final link in links) link.participantProfileId: link};
    final participations = [
      for (final p
          in await repository.contestParticipationRepository.listForProfiles(
            linkOf.keys.toSet(),
          ))
        if (p.roleType == RoleType.pilot) p,
    ];
    if (participations.isEmpty) {
      return (rows: const <PastParticipation>[], hasMore: false);
    }
    final contests = await repository.contestRepository.findByIds({
      for (final p in participations) p.contestId,
    });
    final active = {
      for (final i
          in await repository.invitationRepository.listForParticipations([
            for (final p in participations) p.id,
          ]))
        if (i.isActive) i.contestParticipationId: i,
    };
    final now = _clock().toUtc();
    final rows = <PastParticipation>[
      for (final participation in participations)
        if (contests[participation.contestId] case final contest?)
          // Exactly what [participationsFor] leaves out, so the two lists
          // never overlap: finished, and no invitation that still opens
          // (which honors an explicit expiry as well as the 24 hours).
          if (contest.lifecycleState == LifecycleState.completed &&
              !_opens(active[participation.id], contest, participation, now))
            PastParticipation(
              link: linkOf[participation.participantProfileId]!,
              participation: participation,
              contest: contest,
            ),
    ];
    rows.sort((a, b) {
      final byStart = b.contest.startDateTime.compareTo(
        a.contest.startDateTime,
      );
      return byStart != 0
          ? byStart
          : a.participation.id.value.compareTo(b.participation.id.value);
    });
    final page = rows.skip(offset).take(limit).toList();
    return (rows: page, hasMore: offset + page.length < rows.length);
  }

  static bool _opens(
    Invitation? invitation,
    Contest contest,
    ContestParticipation participation,
    DateTime now,
  ) =>
      invitation != null &&
      InvitationService.opening(invitation, contest, participation, now) !=
          null;

  // -- internals ----------------------------------------------------------

  bool _isLinkable(Account account) =>
      account.kind == AccountKind.registered &&
      account.status == AccountStatus.active;

  Future<void> _requireLinkable(Id accountId) async {
    final account = await repository.accountRepository.findById(accountId);
    if (account == null || !_isLinkable(account)) {
      throw ParticipantLinkError.linkNotFound();
    }
  }

  /// The email matches of [accountId] with an invitation that still opens.
  ///
  /// Empty unless the account is an active registered account with a
  /// verified email.
  Future<
    List<
      ({
        LinkCandidate candidate,
        bool confirmedElsewhere,
        ParticipantAccountLink? own,
      })
    >
  >
  _matching(Id accountId) async {
    final account = await repository.accountRepository.findById(accountId);
    final email = account?.email;
    if (account == null ||
        !_isLinkable(account) ||
        !account.emailVerified ||
        email == null) {
      return const [];
    }
    final profiles = await repository.participantProfileRepository.listByEmail(
      email,
    );
    if (profiles.isEmpty) return const [];
    final links = await repository.participantAccountLinkRepository
        .listForProfiles([for (final p in profiles) p.id]);
    final reachable = await _openParticipations({
      for (final p in profiles) p.id,
    });
    return [
      for (final profile in profiles)
        if ((reachable[profile.id] ?? const []).isNotEmpty)
          (
            candidate: LinkCandidate(
              id: invitations.codec.candidateIdFor(
                accountId: accountId,
                profileId: profile.id,
              ),
              profileId: profile.id,
              firstName: profile.firstName,
              lastName: profile.lastName,
              contests: [
                for (final r in reachable[profile.id]!)
                  CandidateContest.of(r.contest),
              ],
            ),
            confirmedElsewhere: links.any(
              (l) =>
                  l.participantProfileId == profile.id &&
                  l.isConfirmed &&
                  l.accountId != accountId,
            ),
            own: links
                .where(
                  (l) =>
                      l.participantProfileId == profile.id &&
                      l.accountId == accountId,
                )
                .firstOrNull,
          ),
    ];
  }

  /// The match for [profileId], or `link_not_found` when it is not one of
  /// [accountId]'s email matches right now.
  Future<
    ({
      LinkCandidate candidate,
      bool confirmedElsewhere,
      ParticipantAccountLink? own,
    })
  >
  _matchOf(Id profileId, Id accountId) async {
    for (final match in await _matching(accountId)) {
      if (match.candidate.profileId == profileId) return match;
    }
    throw ParticipantLinkError.linkNotFound();
  }

  Future<ParticipantAccountLink?> _existingConfirmed(
    Id profileId,
    Id accountId,
  ) async {
    final confirmed = await repository.participantAccountLinkRepository
        .findConfirmedForProfile(profileId);
    if (confirmed == null) return null;
    if (confirmed.accountId != accountId) {
      throw ParticipantLinkError.alreadyLinked();
    }
    return confirmed;
  }

  /// Makes the link of [accountId] to [profileId] Confirmed, claiming the
  /// guests of the profile, as one transaction.
  Future<ParticipantAccountLink> _confirm({
    required Id profileId,
    required Id accountId,
    required ParticipantLinkOrigin origin,
  }) async {
    final links = repository.participantAccountLinkRepository;
    final existing = await _existingConfirmed(profileId, accountId);
    if (existing != null) {
      // A repeat changes the link not at all, but a guest may have opened a
      // later invitation of the profile since: claiming is idempotent (rows
      // already claimed match nothing), so a Confirmed link never keeps
      // unclaimed guest entries.
      final guests = await _guestsOf(profileId);
      if (guests.isEmpty) return existing;
      return links.saveClaimingGuests(existing, guestAccountIds: guests);
    }

    final earlier = await links.find(
      participantProfileId: profileId,
      accountId: accountId,
    );
    final now = _clock().toUtc();
    // Re-opening an Ended (or Candidate) row keeps its id, its creation time
    // and its revision, so the pair stays one row.
    final link = ParticipantAccountLink(
      id: earlier?.id ?? _newId(),
      participantProfileId: profileId,
      accountId: accountId,
      status: ParticipantLinkStatus.confirmed,
      origin: origin,
      createdAt: earlier?.createdAt ?? now,
      confirmedAt: now,
      revision: earlier?.revision ?? 0,
    );
    final guests = await _guestsOf(profileId);
    try {
      final stored = await links.saveClaimingGuests(
        link,
        guestAccountIds: guests,
      );
      _logger.info(
        'Account ${accountId.value} linked to a profile by '
        '${origin.name} (${guests.length} guest accounts claimed).',
      );
      return stored;
    } on Object {
      // A concurrent request may have confirmed first: the database refuses
      // a second Confirmed link for the profile. Whoever won is the answer:
      // the same account is a repeat, another account is `already_linked`.
      final winner = await links.findConfirmedForProfile(profileId);
      if (winner == null) rethrow;
      if (winner.accountId != accountId) {
        throw ParticipantLinkError.alreadyLinked();
      }
      return winner;
    }
  }

  ParticipantAccountLink _ended(ParticipantAccountLink link) =>
      ParticipantAccountLink(
        id: link.id,
        participantProfileId: link.participantProfileId,
        accountId: link.accountId,
        status: ParticipantLinkStatus.ended,
        origin: link.origin,
        createdAt: link.createdAt,
        confirmedAt: link.confirmedAt,
        endedAt: _clock().toUtc(),
        revision: link.revision,
      );

  Future<List<Invitation>> _invitationsOf(Id profileId) async {
    final participations = await repository.contestParticipationRepository
        .listForProfile(profileId);
    if (participations.isEmpty) return const [];
    return repository.invitationRepository.listForParticipations([
      for (final p in participations) p.id,
    ]);
  }

  /// The guest accounts that opened an invitation of [profileId]'s
  /// participations, across every invitation of every participation (a
  /// regenerated invitation has its own guest).
  Future<List<Id>> _guestsOf(Id profileId) async => {
    for (final invitation in await _invitationsOf(profileId))
      if (invitation.redeemedByAccountId ==
          invitations.codec.guestAccountIdFor(invitation.id))
        invitation.redeemedByAccountId!,
  }.toList();

  /// For each of [profileIds], the pilot participations whose active
  /// invitation opens now, with their contest, read in bulk.
  Future<
    Map<
      Id,
      List<
        ({
          ContestParticipation participation,
          Contest contest,
          Invitation invitation,
          bool readOnly,
        })
      >
    >
  >
  _openParticipations(Set<Id> profileIds) async {
    final participations = [
      for (final p
          in await repository.contestParticipationRepository.listForProfiles(
            profileIds,
          ))
        if (p.roleType == RoleType.pilot) p,
    ];
    if (participations.isEmpty) return const {};
    final invitationRows = await repository.invitationRepository
        .listForParticipations([for (final p in participations) p.id]);
    final active = {
      for (final i in invitationRows)
        if (i.isActive) i.contestParticipationId: i,
    };
    final contests = await repository.contestRepository.findByIds({
      for (final p in participations)
        if (active.containsKey(p.id)) p.contestId,
    });
    final now = _clock().toUtc();
    final found =
        <
          Id,
          List<
            ({
              ContestParticipation participation,
              Contest contest,
              Invitation invitation,
              bool readOnly,
            })
          >
        >{};
    for (final participation in participations) {
      final invitation = active[participation.id];
      final contest = contests[participation.contestId];
      if (invitation == null || contest == null) continue;
      final opens = InvitationService.opening(
        invitation,
        contest,
        participation,
        now,
      );
      if (opens == null) continue;
      found.putIfAbsent(participation.participantProfileId, () => []).add((
        participation: participation,
        contest: contest,
        invitation: invitation,
        readOnly: opens.readOnly,
      ));
    }
    for (final rows in found.values) {
      rows.sort(
        (a, b) => a.contest.startDateTime.compareTo(b.contest.startDateTime),
      );
    }
    return found;
  }
}
