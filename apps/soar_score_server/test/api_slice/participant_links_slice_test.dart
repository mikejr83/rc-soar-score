import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_server/handler.dart';
import 'package:test/test.dart';

import 'gated_repository.dart';
import 'slice_client.dart';

const _contestId = '019c0000-0000-7000-8000-000000000045';
const _secret = 'a-test-secret-that-is-at-least-32-bytes-long';
const _email = 'pat.pilot@example.com';

String _profileId(int n) => '019c0000-0000-7000-8000-00000000c1${_two(n)}';
String _participationId(int n) =>
    '019c0000-0000-7000-8000-00000000d2${_two(n)}';
String _two(int n) => n.toString().padLeft(2, '0');

const _goodScore = {
  'time_flown': 540,
  'launch_height': 45,
  'landing': 'points_50',
};

/// Linking a pilot's account to a participant profile over a real database:
/// the service the account routes of #545 will call, with the guest entries
/// a pilot made before signing in following the account.
void main() {
  final postgresMissing = PostgresConfig.fromEnvironment() == null;
  for (final backend in SliceBackend.values) {
    group(
      backend.name,
      () => _tests(backend),
      skip: backend == SliceBackend.postgres && postgresMissing
          ? 'no PostgreSQL instance configured (set DATABASE_URL or POSTGRES_PASSWORD)'
          : false,
    );
  }
}

/// An [core.InvitationService] that lets a guest open the link just before each
/// of the account's attempts, the way a concurrent anonymous open would.
class _GuestOpensBetweenAttempts extends core.InvitationService {
  _GuestOpensBetweenAttempts(super.repository, super.codec, {super.clock});

  String? credential;
  core.InvitationResolution? guest;

  @override
  Future<core.InvitationResolution?> resolveForAccount(
    core.Invitation invitation,
    core.Id accountId,
  ) async {
    guest = await resolve(credential!);
    return super.resolveForAccount(invitation, accountId);
  }
}

void _tests(SliceBackend backend) {
  late SliceClient api;
  late core.Repository repository;
  late core.InvitationService invitations;
  late core.ParticipantLinkService links;
  late Handler handler;
  late int matrixRevision;
  late core.Id pat; // a registered account with the verified email of pilot 1
  late core.Id otherAccount;
  var clock = DateTime.utc(2026, 10, 17, 16);

  core.Id id(String value) => core.Id.parse(value);

  Future<core.Id> account(
    String first, {
    String? email,
    bool verified = true,
  }) async {
    final accountId = core.Id.create();
    await repository.accountRepository.save(
      core.Account(
        id: accountId,
        firstName: first,
        lastName: 'Account',
        email: email,
        emailVerified: verified,
        kind: core.AccountKind.registered,
        createdAt: clock,
        updatedAt: clock,
      ),
    );
    return accountId;
  }

  Future<void> listInDirectory(core.Id accountId, {bool listed = true}) =>
      repository.participantDirectoryEntryRepository
          .save(
            core.ParticipantDirectoryEntry(
              id: core.Id.create(),
              accountId: accountId,
              firstName: 'Listed',
              lastName: 'Pilot',
              isListed: listed,
              createdAt: clock,
              updatedAt: clock,
            ),
          )
          .then((_) {});

  Future<void> contestAction(String action) async => api.expectOk(
    'POST',
    '/contests/$_contestId/actions',
    body: {
      'action': action,
      'base_revision': (await api.expectOk(
        'GET',
        '/contests/$_contestId',
      ))['revision'],
    },
  );

  setUp(() async {
    clock = DateTime.now().toUtc();
    api = await SliceClient.open(backend);
    repository = Repository(api.database);
    invitations = core.InvitationService(
      repository,
      core.InvitationCodec.fromText(_secret),
      clock: () => clock,
    );
    links = core.ParticipantLinkService(
      repository,
      invitations,
      clock: () => clock,
    );
    handler = createServerHandler(
      api.database,
      authMiddleware: fixedPrincipal(Principal(accountId: api.director)),
      invitationSecret: _secret,
    );
    pat = await account('Pat', email: _email);
    otherAccount = await account('Sam', email: 'sam@example.com');
    await listInDirectory(otherAccount);
    await api.expectOk(
      'POST',
      '/contests',
      status: 201,
      body: {
        'id': _contestId,
        'name': 'Spring Open',
        'start_date_time': '2026-10-17T14:00:00.000Z',
        'end_date_time': '2026-10-18T22:00:00.000Z',
        'timezone': 'America/Denver',
      },
    );
    await api.expectOk(
      'POST',
      '/contests/$_contestId/configuration',
      status: 201,
      body: {
        'base_revision_number': 0,
        'discipline_profile_id': core.SystemDisciplineProfiles.f5jId.value,
        'config': {
          'core': <String, Object?>{},
          'discipline': {'working_time': 600},
        },
      },
    );
    for (var n = 1; n <= 2; n++) {
      await api.expectOk(
        'POST',
        '/participants',
        status: 201,
        body: {
          'id': _profileId(n),
          'first_name': 'Pilot$n',
          'last_name': 'Rivera',
          // Typed with capitals: the match ignores case.
          if (n == 1) 'email': 'Pat.Pilot@Example.com',
        },
      );
      await api.expectOk(
        'POST',
        '/contests/$_contestId/participations',
        status: 201,
        body: {
          'id': _participationId(n),
          'participant_profile_id': _profileId(n),
          'role_id': core.SystemRoles.pilotId.value,
        },
      );
    }
    final matrix = await api.expectOk(
      'POST',
      '/contests/$_contestId/matrix/draws',
      status: 201,
      body: {
        'id': '019c0000-0000-7000-8000-000000000546',
        'rounds': 2,
        'groups_per_round': 1,
        'random_seed': 7,
      },
    );
    expect(matrix['rounds'], isNotEmpty);
    matrixRevision =
        (await repository.matrixRevisionRepository.latestForContest(
          id(_contestId),
        ))!.revisionNumber;
    await contestAction('openScoring');
  });
  tearDown(() => api.close());

  /// Links [accountId] through the invitation [credential], as a pilot who
  /// opens it while signed in does.
  Future<core.ParticipantAccountLink> linkFromInvitation({
    required String credential,
    required core.Id accountId,
  }) async => (await links.claimInvitation(
    credential: credential,
    accountId: accountId,
  )).link;

  Future<core.IssuedInvitation> issue(int pilot) => invitations.issue(
    contestId: id(_contestId),
    participationId: id(_participationId(pilot)),
    issuedBy: api.director,
    clientMutationId: 'issue-$pilot',
  );

  /// Opens [credential] as an anonymous guest and submits round 1.
  Future<core.Id> guestScores(String credential) async {
    final resolved = await invitations.resolve(credential);
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/self-scoring/rounds/1/scores'),
        body: jsonEncode({
          'client_mutation_id': 'm-1',
          'matrix_revision': matrixRevision,
          'components': _goodScore,
        }),
        headers: {'authorization': 'Bearer ${resolved.sessionToken}'},
      ),
    );
    expect(response.statusCode, 201, reason: await response.readAsString());
    return resolved.access.guestAccountId;
  }

  Future<Set<String>> column(String sql) async => {
    for (final row in await api.database.customSelect(sql).get())
      row.read<String?>('v') ?? 'null',
  };

  Future<Set<String>> attemptActors() =>
      column('SELECT actor_id AS v FROM score_attempts');

  Future<Set<String>> redeemers(int pilot) => column(
    "SELECT redeemed_by_account_id AS v FROM invitations "
    "WHERE contest_participation_id = '${_participationId(pilot)}'",
  );

  Future<Set<String>> auditActors() => column(
    'SELECT actor_id AS v FROM audit_events WHERE actor_id IS NOT NULL',
  );

  Future<Set<String>> mutationActors() => column(
    'SELECT actor_id AS v FROM mutation_records WHERE authority = '
    "'Participant'",
  );

  group('candidates', () {
    test('need a verified email and an invitation that opens', () async {
      expect(await links.candidatesFor(pat), isEmpty, reason: 'not invited');

      await issue(1);
      final candidates = await links.candidatesFor(pat);
      expect(candidates, hasLength(1));
      expect(candidates.single.profileId, id(_profileId(1)));
      expect(candidates.single.firstName, 'Pilot1');
      expect(candidates.single.contests.single.name, 'Spring Open');

      final unverified = await account(
        'Pat2',
        email: 'pat2@example.com',
        verified: false,
      );
      await api.expectOk(
        'POST',
        '/participants',
        status: 201,
        body: {
          'id': _profileId(9),
          'first_name': 'Nine',
          'last_name': 'X',
          'email': 'pat2@example.com',
        },
      );
      expect(await links.candidatesFor(unverified), isEmpty);
      expect(await links.candidatesFor(otherAccount), isEmpty);
      expect(await links.candidatesFor(core.Id.create()), isEmpty);
    });

    test(
      'only list the caller\'s own match, never a guest or other kind',
      () async {
        await issue(1);
        final guest = invitations.codec.guestAccountIdFor(
          (await repository.invitationRepository.listForParticipation(
            id(_participationId(1)),
          )).single.id,
        );
        expect(await links.candidatesFor(guest), isEmpty);
      },
    );

    test('are computed on read and write nothing', () async {
      await issue(1);
      await links.candidatesFor(pat);
      expect(
        await repository.participantAccountLinkRepository.listForAccount(pat),
        isEmpty,
      );
    });
  });

  group('confirming a candidate', () {
    test('links the pilot and claims what the guest did, together', () async {
      final issued = await issue(1);
      final guest = await guestScores(issued.credential);
      expect(await attemptActors(), {guest.value});
      expect(await redeemers(1), {guest.value});
      expect(await auditActors(), contains(guest.value));
      expect(await mutationActors(), {guest.value});

      final link = await links.confirmCandidate(
        profileId: id(_profileId(1)),
        accountId: pat,
      );

      expect(link.status, core.ParticipantLinkStatus.confirmed);
      expect(link.origin, core.ParticipantLinkOrigin.emailMatch);
      expect(await attemptActors(), {pat.value});
      expect(await redeemers(1), {pat.value});
      expect(await auditActors(), isNot(contains(guest.value)));
      expect(await mutationActors(), {pat.value});
      expect(
        await repository.accountRepository.findById(guest),
        isNotNull,
        reason: 'the guest account is kept',
      );
      expect(await links.candidatesFor(pat), isEmpty);
    });

    test('repeating it changes nothing', () async {
      final issued = await issue(1);
      await guestScores(issued.credential);
      final first = await links.confirmCandidate(
        profileId: id(_profileId(1)),
        accountId: pat,
      );
      final again = await links.confirmCandidate(
        profileId: id(_profileId(1)),
        accountId: pat,
      );
      expect(again, first);
      expect(
        await repository.participantAccountLinkRepository.listForProfile(
          id(_profileId(1)),
        ),
        [first],
      );
    });

    test(
      'a repeat claims a guest that opened the link after the link',
      () async {
        final issued = await issue(1);
        await links.confirmCandidate(
          profileId: id(_profileId(1)),
          accountId: pat,
        );
        final guest = await guestScores(issued.credential);
        expect(await attemptActors(), {guest.value});

        final again = await links.confirmCandidate(
          profileId: id(_profileId(1)),
          accountId: pat,
        );

        expect(again.accountId, pat);
        expect(await attemptActors(), {pat.value});
        expect(await redeemers(1), {pat.value});
      },
    );

    test('is refused for a profile that is not a match', () async {
      await issue(1);
      await expectLater(
        links.confirmCandidate(profileId: id(_profileId(2)), accountId: pat),
        throwsA(
          isA<core.ParticipantLinkError>().having(
            (e) => e.code,
            'code',
            'link_not_found',
          ),
        ),
      );
      expect(
        await repository.participantAccountLinkRepository.listForAccount(pat),
        isEmpty,
      );
    });

    test('a pilot with no invitation that opens is not a match', () async {
      await expectLater(
        links.confirmCandidate(profileId: id(_profileId(1)), accountId: pat),
        throwsA(isA<core.ParticipantLinkError>()),
      );
    });

    test('declining records it and is not offered again', () async {
      await issue(1);
      await links.declineCandidate(
        profileId: id(_profileId(1)),
        accountId: pat,
      );
      await links.declineCandidate(
        profileId: id(_profileId(1)),
        accountId: pat,
      );

      final stored = await repository.participantAccountLinkRepository
          .listForAccount(pat);
      expect(stored.single.status, core.ParticipantLinkStatus.ended);
      expect(stored.single.confirmedAt, isNull);
      expect(await links.candidatesFor(pat), isEmpty);
      await expectLater(
        links.confirmCandidate(profileId: id(_profileId(1)), accountId: pat),
        throwsA(isA<core.ParticipantLinkError>()),
      );
    });

    test('a second account gets already_linked and changes nothing', () async {
      final issued = await issue(1);
      final guest = await guestScores(issued.credential);
      await links.confirmCandidate(
        profileId: id(_profileId(1)),
        accountId: pat,
      );

      for (final attempt in [
        () => linkFromInvitation(
          credential: issued.credential,
          accountId: otherAccount,
        ),
        () => links.linkFromDirectory(
          profileId: id(_profileId(1)),
          accountId: otherAccount,
          directorAccountId: api.director,
        ),
      ]) {
        await expectLater(
          attempt(),
          throwsA(
            isA<core.ParticipantLinkError>().having(
              (e) => e.code,
              'code',
              'already_linked',
            ),
          ),
        );
      }
      expect(await attemptActors(), {pat.value});
      expect(await redeemers(1), {pat.value});
      expect(
        await repository.participantAccountLinkRepository.listForAccount(
          otherAccount,
        ),
        isEmpty,
      );
      expect(guest, isNot(pat));
    });

    test('two accounts racing leave exactly one Confirmed link', () async {
      final issued = await issue(1);
      await guestScores(issued.credential);

      final results = await Future.wait([
        links
            .confirmCandidate(profileId: id(_profileId(1)), accountId: pat)
            .then<Object>((link) => link, onError: (Object e) => e),
        linkFromInvitation(
          credential: issued.credential,
          accountId: otherAccount,
        ).then<Object>((link) => link, onError: (Object e) => e),
      ]);

      expect(results.whereType<core.ParticipantAccountLink>(), hasLength(1));
      expect(
        results.whereType<core.ParticipantLinkError>().map((e) => e.code),
        ['already_linked'],
      );
      final winner = results
          .whereType<core.ParticipantAccountLink>()
          .single
          .accountId;
      expect(await attemptActors(), {winner.value});
      expect(await redeemers(1), {winner.value});
      final confirmed =
          (await repository.participantAccountLinkRepository.listForProfile(
            id(_profileId(1)),
          )).where((l) => l.isConfirmed);
      expect(confirmed, hasLength(1));
    });
  });

  group('invitation and directory links', () {
    test('an invitation link confirms at once and claims the guest', () async {
      final issued = await issue(1);
      final guest = await guestScores(issued.credential);

      final link = await linkFromInvitation(
        credential: issued.credential,
        accountId: otherAccount, // the email need not match the profile's
      );

      expect(link.origin, core.ParticipantLinkOrigin.invitationRedemption);
      expect(link.isConfirmed, isTrue);
      expect(await attemptActors(), {otherAccount.value});
      expect(await redeemers(1), {otherAccount.value});
      expect(guest, isNot(otherAccount));
    });

    test('a link that does not open is the usual invalid link', () async {
      await expectLater(
        linkFromInvitation(credential: 'nonsense', accountId: pat),
        throwsA(isA<core.InvitationAccessError>()),
      );
      expect(
        await repository.participantAccountLinkRepository.listForAccount(pat),
        isEmpty,
      );
    });

    test('a guest or unknown account cannot be linked', () async {
      final issued = await issue(1);
      final guest = await guestScores(issued.credential);
      for (final who in [guest, core.Id.create()]) {
        await expectLater(
          linkFromInvitation(credential: issued.credential, accountId: who),
          throwsA(isA<core.ParticipantLinkError>()),
        );
      }
    });

    test('the directory copy is active at once and idempotent', () async {
      final link = await links.linkFromDirectory(
        profileId: id(_profileId(2)),
        accountId: otherAccount,
        directorAccountId: api.director,
      );
      expect(link.origin, core.ParticipantLinkOrigin.directoryPull);
      expect(link.isConfirmed, isTrue);
      expect(
        await links.linkFromDirectory(
          profileId: id(_profileId(2)),
          accountId: otherAccount,
          directorAccountId: api.director,
        ),
        link,
      );
    });

    test('an unlisted or unknown pilot is refused, as nothing', () async {
      final hidden = await account('Hidden');
      await listInDirectory(hidden, listed: false);
      final unlisted = await account('Nolist');
      for (final who in [hidden, unlisted]) {
        await expectLater(
          links.linkFromDirectory(
            profileId: id(_profileId(2)),
            accountId: who,
            directorAccountId: api.director,
          ),
          throwsA(
            isA<core.ParticipantLinkError>().having(
              (e) => e.code,
              'code',
              'link_not_found',
            ),
          ),
        );
      }
      expect(
        await repository.participantAccountLinkRepository.listForProfile(
          id(_profileId(2)),
        ),
        isEmpty,
      );
    });

    test('the profile may not have reached the server yet', () async {
      final unsynced = core.Id.create();
      final link = await links.linkFromDirectory(
        profileId: unsynced,
        accountId: otherAccount,
        directorAccountId: api.director,
      );
      expect(link.participantProfileId, unsynced);
    });

    test('a profile of another director is refused', () async {
      await expectLater(
        links.linkFromDirectory(
          profileId: id(_profileId(2)),
          accountId: otherAccount,
          directorAccountId: core.Id.create(),
        ),
        throwsA(
          isA<core.ParticipantLinkError>().having(
            (e) => e.code,
            'code',
            'profile_not_owned',
          ),
        ),
      );
    });

    test(
      'a later invitation of a linked profile needs no confirmation',
      () async {
        await links.linkFromDirectory(
          profileId: id(_profileId(2)),
          accountId: otherAccount,
          directorAccountId: api.director,
        );
        expect(await links.participationsFor(otherAccount), isEmpty);

        await issue(2);

        final rows = await links.participationsFor(otherAccount);
        expect(rows.single.participationId, id(_participationId(2)));
        expect(rows.single.contest.name, 'Spring Open');
        expect(rows.single.readOnly, isFalse);
      },
    );
  });

  group('ending a link', () {
    test(
      'hands the invitation back to the guest, keeps the account\'s scores',
      () async {
        final issued = await issue(1);
        final guest = await guestScores(issued.credential);
        final link = await links.confirmCandidate(
          profileId: id(_profileId(1)),
          accountId: pat,
        );
        expect(await links.participationsFor(pat), hasLength(1));

        final ended = await links.end(linkId: link.id, accountId: pat);

        expect(ended.status, core.ParticipantLinkStatus.ended);
        expect(ended.endedAt, isNotNull);
        expect(await links.participationsFor(pat), isEmpty);
        expect(await redeemers(1), {guest.value});
        expect(await attemptActors(), {pat.value});
        expect(
          (await links.end(linkId: link.id, accountId: pat)).status,
          core.ParticipantLinkStatus.ended,
          reason: 'ending twice changes nothing',
        );
        // Not offered again, and the anonymous holder of the link still works.
        expect(await links.candidatesFor(pat), isEmpty);
        final reopened = await invitations.resolve(issued.credential);
        expect(reopened.access.guestAccountId, guest);
      },
    );

    test('an invitation no guest ever held goes back to nobody', () async {
      final issued = await issue(1);
      final link = await linkFromInvitation(
        credential: issued.credential,
        accountId: pat,
      );
      // The account opened it (no guest account was made for it).
      await api.database.customStatement(
        "UPDATE invitations SET redeemed_by_account_id = '${pat.value}' "
        "WHERE contest_participation_id = '${_participationId(1)}'",
      );
      await links.end(linkId: link.id, accountId: pat);
      expect(await redeemers(1), {'null'});
      final opened = await invitations.resolve(issued.credential);
      expect(opened.access.guestAccountId, isNot(pat));
    });

    test('is only the account\'s own', () async {
      final issued = await issue(1);
      final link = await linkFromInvitation(
        credential: issued.credential,
        accountId: pat,
      );
      for (final who in [otherAccount, core.Id.create()]) {
        await expectLater(
          links.end(linkId: link.id, accountId: who),
          throwsA(
            isA<core.ParticipantLinkError>().having(
              (e) => e.code,
              'code',
              'link_not_found',
            ),
          ),
        );
      }
      await expectLater(
        links.end(linkId: core.Id.create(), accountId: pat),
        throwsA(isA<core.ParticipantLinkError>()),
      );
      expect(
        (await repository.participantAccountLinkRepository.findById(link.id))!
            .isConfirmed,
        isTrue,
      );
    });

    test('a pilot can link again after ending, on the same row', () async {
      final issued = await issue(1);
      final first = await linkFromInvitation(
        credential: issued.credential,
        accountId: pat,
      );
      await links.end(linkId: first.id, accountId: pat);

      final again = await linkFromInvitation(
        credential: issued.credential,
        accountId: pat,
      );

      expect(again.id, first.id);
      expect(again.isConfirmed, isTrue);
      expect(again.endedAt, isNull);
      expect(
        await repository.participantAccountLinkRepository.listForProfile(
          id(_profileId(1)),
        ),
        [again],
      );
    });
  });

  group('the list of participations', () {
    test('holds only confirmed links with an active invitation', () async {
      await issue(1);
      await issue(2);
      await linkFromInvitation(
        credential: (await issue(1)).credential,
        accountId: pat,
      );

      final rows = await links.participationsFor(pat);

      expect(rows.map((r) => r.participationId), [id(_participationId(1))]);
      expect(await links.participationsFor(otherAccount), isEmpty);
    });

    test('a contest drops off a day after it completed', () async {
      final issued = await issue(1);
      await linkFromInvitation(credential: issued.credential, accountId: pat);
      await api.database.customStatement(
        "UPDATE contests SET lifecycle_state = 'Completed', "
        "updated_at = '${clock.toIso8601String()}' WHERE id = '$_contestId'",
      );
      expect((await links.participationsFor(pat)).single.readOnly, isTrue);

      clock = clock.add(const Duration(hours: 25));

      expect(await links.participationsFor(pat), isEmpty);
    });
  });

  /// Submits [round] as the holder of [token] and returns the status.
  Future<int> submitAs(String token, int round, String key) async {
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/self-scoring/rounds/$round/scores'),
        body: jsonEncode({
          'client_mutation_id': key,
          'matrix_revision': matrixRevision,
          'components': _goodScore,
        }),
        headers: {'authorization': 'Bearer $token'},
      ),
    );
    return response.statusCode;
  }

  group('concurrent opens', () {
    test('two opens by one account after a guest took the invitation back '
        'both succeed and claim the guest once', () async {
      final issued = await issue(1);
      await guestScores(issued.credential);
      await linkFromInvitation(credential: issued.credential, accountId: pat);
      // The pilot's guest browser opens the link again and scores round 2.
      final guestAgain = await invitations.resolve(issued.credential);
      expect(await submitAs(guestAgain.sessionToken, 2, 'guest-2'), 201);
      final guest = guestAgain.access.guestAccountId;
      expect(await redeemers(1), {guest.value});

      final gated = GatedRepository(api.database);
      final waiting = <Completer<void>>[];
      gated.beforeClaim = () {
        final gate = Completer<void>();
        waiting.add(gate);
        // Both opens have found the guest; release the first, and the second
        // once the first has written.
        if (waiting.length == 2) waiting.first.complete();
        return gate.future;
      };
      gated.afterClaim = () async {
        if (!waiting.last.isCompleted) waiting.last.complete();
      };
      final racingInvitations = core.InvitationService(
        gated,
        invitations.codec,
        clock: () => clock,
      );
      final racing = core.ParticipantLinkService(
        gated,
        racingInvitations,
        clock: () => clock,
      );

      final opened = await Future.wait([
        for (var i = 0; i < 2; i++)
          racing.openParticipation(
            participationId: id(_participationId(1)),
            accountId: pat,
          ),
      ]);

      for (final session in opened) {
        expect(
          (await invitations.authorize(session.sessionToken)).guestAccountId,
          pat,
        );
      }
      expect(await attemptActors(), {pat.value});
      expect(await column('SELECT COUNT(*) AS v FROM score_attempts'), {
        '2',
      }, reason: 'the guest\'s attempt moved once, none was lost or copied');
      expect(await redeemers(1), {pat.value});
    });

    test('a claim paused before it writes does not take what a guest did '
        'after the link ended', () async {
      final issued = await issue(1);
      await guestScores(issued.credential);
      final link = await linkFromInvitation(
        credential: issued.credential,
        accountId: pat,
      );
      // The pilot's guest browser opens the link again: the guest holds the
      // invitation, so the account's next open has something to claim.
      final guest = (await invitations.resolve(issued.credential))
          .access
          .guestAccountId;

      final gated = GatedRepository(api.database);
      final paused = Completer<void>();
      final release = Completer<void>();
      gated.beforeClaim = () {
        paused.complete();
        return release.future;
      };
      final racingInvitations = core.InvitationService(
        gated,
        invitations.codec,
        clock: () => clock,
      );
      final racing = core.ParticipantLinkService(
        gated,
        racingInvitations,
        clock: () => clock,
      );

      final opening = racing.openParticipation(
        participationId: id(_participationId(1)),
        accountId: pat,
      );
      final outcome = expectLater(
        opening,
        throwsA(
          isA<core.ParticipantLinkError>().having(
            (e) => e.code,
            'code',
            'link_not_found',
          ),
        ),
      );
      await paused.future;
      // The account ends the link, and the guest scores another round.
      await links.end(linkId: link.id, accountId: pat);
      final again = await invitations.resolve(issued.credential);
      expect(await submitAs(again.sessionToken, 2, 'guest-2'), 201);
      release.complete();
      await outcome;

      expect(await attemptActors(), {pat.value, guest.value});
      expect(await redeemers(1), {guest.value});
      expect(
        (await invitations.authorize(again.sessionToken)).guestAccountId,
        guest,
        reason: 'the guest keeps a working session',
      );
    });

    test('ending a link while a guest claim completes hands the invitation '
        'back to the guest', () async {
      final issued = await issue(1);
      await guestScores(issued.credential);
      final link = await linkFromInvitation(
        credential: issued.credential,
        accountId: pat,
      );
      // The guest holds the invitation when the account starts to end the link.
      final guestAgain = await invitations.resolve(issued.credential);
      final guest = guestAgain.access.guestAccountId;
      expect(await redeemers(1), {guest.value});

      final gated = GatedRepository(api.database);
      final paused = Completer<void>();
      final release = Completer<void>();
      gated.beforeRelease = () {
        paused.complete();
        return release.future;
      };
      final racing = core.ParticipantLinkService(
        gated,
        core.InvitationService(gated, invitations.codec, clock: () => clock),
        clock: () => clock,
      );

      final ending = racing.end(linkId: link.id, accountId: pat);
      await paused.future;
      // The account's own open claims the guest while the end is paused.
      await links.openParticipation(
        participationId: id(_participationId(1)),
        accountId: pat,
      );
      expect(await redeemers(1), {pat.value});
      release.complete();
      final ended = await ending;

      expect(ended.status, core.ParticipantLinkStatus.ended);
      expect(await redeemers(1), {guest.value});
      expect(
        (await invitations.authorize(guestAgain.sessionToken)).guestAccountId,
        guest,
      );
    });

    test('an open of a never-opened invitation that waits while the link '
        'ends leaves the invitation unredeemed', () async {
      await issue(1);
      // A directory link: no guest ever opened the invitation.
      await listInDirectory(pat);
      final link = await links.linkFromDirectory(
        profileId: id(_profileId(1)),
        accountId: pat,
        directorAccountId: api.director,
      );
      expect(await redeemers(1), {'null'});

      final gated = GatedRepository(api.database);
      final paused = Completer<void>();
      final release = Completer<void>();
      gated.beforeRedeem = (newRedeemer, needsLink) {
        expect(needsLink, isTrue, reason: 'an account open needs its link');
        paused.complete();
        return release.future;
      };
      final racing = core.ParticipantLinkService(
        gated,
        core.InvitationService(gated, invitations.codec, clock: () => clock),
        clock: () => clock,
      );

      final opening = racing.openParticipation(
        participationId: id(_participationId(1)),
        accountId: pat,
      );
      final outcome = expectLater(
        opening,
        throwsA(
          isA<core.ParticipantLinkError>().having(
            (e) => e.code,
            'code',
            'link_not_found',
          ),
        ),
      );
      await paused.future;
      await links.end(linkId: link.id, accountId: pat);
      release.complete();
      await outcome;

      expect(await redeemers(1), {
        'null',
      }, reason: 'the ended account holds none');
    });

    test('ending a link twice at once is a no-op for the second', () async {
      await issue(1);
      await listInDirectory(pat);
      final link = await links.linkFromDirectory(
        profileId: id(_profileId(1)),
        accountId: pat,
        directorAccountId: api.director,
      );
      final gated = GatedRepository(api.database);
      final waiting = <Completer<void>>[];
      gated.beforeRelease = () {
        // Both ends have read the Confirmed link; the first goes on once the
        // second is waiting too.
        final gate = Completer<void>();
        waiting.add(gate);
        if (waiting.length == 2) {
          waiting.first.complete();
          waiting.last.complete();
        }
        return gate.future;
      };
      final racing = core.ParticipantLinkService(
        gated,
        core.InvitationService(gated, invitations.codec, clock: () => clock),
        clock: () => clock,
      );

      final ended = await Future.wait([
        for (var i = 0; i < 2; i++) racing.end(linkId: link.id, accountId: pat),
      ]);

      expect(
        ended.map((l) => l.status),
        everyElement(core.ParticipantLinkStatus.ended),
      );
    });

    test('an open paused after its claim cannot bring back a link that was '
        'ended meanwhile', () async {
      final issued = await issue(1);
      await guestScores(issued.credential);
      final link = await linkFromInvitation(
        credential: issued.credential,
        accountId: pat,
      );
      final guestAgain = await invitations.resolve(issued.credential);
      final guest = guestAgain.access.guestAccountId;

      final gated = GatedRepository(api.database);
      final claimed = Completer<void>();
      final resume = Completer<void>();
      var first = true;
      gated.afterClaim = () async {
        if (!first) return;
        first = false;
        claimed.complete();
        await resume.future;
      };
      final racing = core.ParticipantLinkService(
        gated,
        core.InvitationService(gated, invitations.codec, clock: () => clock),
        clock: () => clock,
      );

      final opening = racing.openParticipation(
        participationId: id(_participationId(1)),
        accountId: pat,
      );
      final outcome = expectLater(
        opening,
        throwsA(
          isA<core.ParticipantLinkError>().having(
            (e) => e.code,
            'code',
            'link_not_found',
          ),
        ),
      );
      await claimed.future;
      // The open has claimed the guest; the account ends the link now, which
      // returns the invitation to the guest.
      await links.end(linkId: link.id, accountId: pat);
      resume.complete();
      await outcome;

      expect(
        (await repository.participantAccountLinkRepository.findById(link.id))!
            .status,
        core.ParticipantLinkStatus.ended,
      );
      expect(await links.participationsFor(pat), isEmpty);
      expect(await redeemers(1), {guest.value});
      expect(
        (await invitations.authorize(guestAgain.sessionToken)).guestAccountId,
        guest,
      );
    });

    test('a guest open paused after its write and an account taking over '
        'are both audited, and only the account\'s session works', () async {
      final issued = await issue(1);
      final guest = await guestScores(issued.credential);
      await linkFromInvitation(credential: issued.credential, accountId: pat);
      Future<int> opens() async => (await column(
        "SELECT COUNT(*) AS v FROM audit_events WHERE action = "
        "'InvitationAccessed'",
      )).map(int.parse).single;
      final before = await opens();

      final gated = GatedRepository(api.database);
      final written = Completer<void>();
      final resume = Completer<void>();
      gated.afterRedeem = (newRedeemer, applied) async {
        if (newRedeemer == guest && applied && !written.isCompleted) {
          written.complete();
          await resume.future;
        }
      };
      final racingInvitations = core.InvitationService(
        gated,
        invitations.codec,
        clock: () => clock,
      );
      final racing = core.ParticipantLinkService(
        gated,
        racingInvitations,
        clock: () => clock,
      );

      final guestOpen = racingInvitations.resolve(issued.credential);
      await written.future;
      expect(await redeemers(1), {guest.value});
      final accountSession = await racing.openParticipation(
        participationId: id(_participationId(1)),
        accountId: pat,
      );
      resume.complete();
      final guestSession = await guestOpen;

      expect(await opens(), before + 2, reason: 'both writes are audited');
      expect(await redeemers(1), {pat.value});
      expect(
        (await invitations.authorize(accountSession.sessionToken))
            .guestAccountId,
        pat,
      );
      await expectLater(
        invitations.authorize(guestSession.sessionToken),
        throwsA(isA<core.InvitationAccessError>()),
      );
    });

    test('an account session outlives an anonymous open of the same link, '
        'which only takes the redeemer back', () async {
      final issued = await issue(1);
      await guestScores(issued.credential);
      await linkFromInvitation(credential: issued.credential, accountId: pat);
      final accountSession = await links.openParticipation(
        participationId: id(_participationId(1)),
        accountId: pat,
      );

      final anonymous = await invitations.resolve(issued.credential);

      expect(
        (await invitations.authorize(accountSession.sessionToken))
            .guestAccountId,
        pat,
      );
      expect(
        (await invitations.authorize(anonymous.sessionToken)).guestAccountId,
        isNot(pat),
      );
    });
  });

  group('contest zones at the REST boundary', () {
    Map<String, Object?> create(String id, String zone) => {
      'id': id,
      'name': 'Zone Test',
      'start_date_time': '2026-10-17T14:00:00.000Z',
      'end_date_time': '2026-10-18T22:00:00.000Z',
      'timezone': zone,
    };

    test('a new contest with an unknown zone is a 400', () async {
      final response = await api.send(
        'POST',
        '/contests',
        body: create('019c0000-0000-7000-8000-000000000a01', 'MDT'),
      );

      expect(response.status, 400);
      expect((response.body['error']! as Map)['code'], 'invalid_request');
      expect(
        await column(
          "SELECT COUNT(*) AS v FROM contests WHERE id = "
          "'019c0000-0000-7000-8000-000000000a01'",
        ),
        {'0'},
      );
    });

    test('replaying the create of a contest stored with a legacy zone '
        'returns it without a duplicate', () async {
      const contest = '019c0000-0000-7000-8000-000000000a02';
      await api.expectOk(
        'POST',
        '/contests',
        status: 201,
        body: create(contest, 'America/Denver'),
      );
      await api.database.customStatement(
        "UPDATE contests SET timezone = 'MDT' WHERE id = '$contest'",
      );

      final replay = await api.send(
        'POST',
        '/contests',
        body: create(contest, 'MDT'),
      );

      expect(replay.status, anyOf(200, 201), reason: '${replay.body}');
      expect(replay.body['id'], contest);
      expect(replay.body['timezone'], 'MDT');
      expect(
        await column(
          "SELECT COUNT(*) AS v FROM contests WHERE id = '$contest'",
        ),
        {'1'},
      );
    });
  });

  group('opening a participation', () {
    test('a failed final attempt does not end a guest session that opened '
        'in between', () async {
      final issued = await issue(1);
      await guestScores(issued.credential);
      await linkFromInvitation(credential: issued.credential, accountId: pat);
      // A guest opens again after the claim: the redeemer is the guest.
      await invitations.resolve(issued.credential);
      final scripted = _GuestOpensBetweenAttempts(
        repository,
        invitations.codec,
        clock: () => clock,
      )..credential = issued.credential;
      final racing = core.ParticipantLinkService(
        repository,
        scripted,
        clock: () => clock,
      );

      await expectLater(
        racing.openParticipation(
          participationId: id(_participationId(1)),
          accountId: pat,
        ),
        throwsA(isA<core.InvitationAccessError>()),
      );

      // The account's open failed, and its last attempt did not reclaim the
      // invitation from the guest who opened in between.
      final guest = scripted.guest!;
      expect(
        (await scripted.authorize(guest.sessionToken)).guestAccountId,
        guest.access.guestAccountId,
      );
    });
  });
}
