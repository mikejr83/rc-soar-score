import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_server/handler.dart';
import 'package:test/test.dart';

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

/// The account routes of a pilot's links (#545 B) over a real database: the
/// participations list, the "Is this you?" candidates, confirm and decline,
/// and the links list and end, as the signed-in pilot calls them.
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

  /// Sets the contest's state directly: completing needs a Running contest.
  Future<void> setLifecycle(core.LifecycleState state) async {
    final contest = await repository.contestRepository.findById(id(_contestId));
    await repository.contestRepository.save(
      contest!.copyWithState(lifecycleState: state, updatedAt: clock),
      metadata: core.MutationMetadata(
        clientMutationId: 'state-${state.name}',
        authority: core.Authority.director,
        clientTime: clock,
        actorId: api.director,
      ),
    );
  }

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

  /// Calls the account routes as [as], like the signed-in app does.
  final callers = <core.Id, Handler>{};
  Future<({int status, Map<String, Object?> json, String text})> call(
    core.Id as,
    String method,
    String path, {
    bool withSecret = true,
  }) async {
    final handler = withSecret
        ? callers.putIfAbsent(
            as,
            () => createServerHandler(
              api.database,
              authMiddleware: fixedPrincipal(Principal(accountId: as)),
              invitationSecret: _secret,
            ),
          )
        : api.handlerFor(as);
    final response = await handler(
      Request(method, Uri.parse('http://localhost/api/v1$path')),
    );
    final text = await response.readAsString();
    return (
      status: response.statusCode,
      json: text.isEmpty
          ? const <String, Object?>{}
          : jsonDecode(text) as Map<String, Object?>,
      text: text,
    );
  }

  Future<List<Object?>> candidates(core.Id as) async =>
      (await call(as, 'GET', '/account/link-candidates')).json['candidates']
          as List<Object?>;

  Future<List<Object?>> participations(core.Id as) async =>
      (await call(as, 'GET', '/account/participations')).json['participations']
          as List<Object?>;

  /// The id [as] sees for the candidate of [profile].
  String cid(core.Id as, String profile) => invitations.codec
      .candidateIdFor(accountId: as, profileId: id(profile))
      .value;

  Future<String> confirm(core.Id as, String profile) async {
    final response = await call(
      as,
      'POST',
      '/account/link-candidates/${cid(as, profile)}/confirm',
    );
    expect(response.status, 200, reason: response.text);
    return response.json['id']! as String;
  }

  group('candidates', () {
    test(
      'show the pilot as typed and the contest, nothing of the director',
      () async {
        await issue(1);

        final response = await call(pat, 'GET', '/account/link-candidates');

        expect(response.status, 200, reason: response.text);
        final list = response.json['candidates']! as List<Object?>;
        final candidate = list.single! as Map<String, Object?>;
        expect(candidate['id'], cid(pat, _profileId(1)));
        expect(candidate['id'], isNot(_profileId(1)));
        expect(response.text, isNot(contains(_profileId(1))));
        expect(candidate['first_name'], 'Pilot1');
        expect(candidate['last_name'], 'Rivera');
        final contest =
            (candidate['contests']! as List<Object?>).single!
                as Map<String, Object?>;
        expect(contest['name'], 'Spring Open');
        expect(contest.keys, isNot(contains('owner_account_id')));
        expect(response.text, isNot(contains(api.director.value)));
        expect(response.text.toLowerCase(), isNot(contains(_email)));
        expect(response.text, isNot(contains(_participationId(1))));
      },
    );

    test('are empty without an invitation or a verified email', () async {
      expect(await candidates(pat), isEmpty, reason: 'not invited');
      await issue(1);
      final unverified = await account(
        'Pat2',
        email: _email.replaceFirst('pat.', 'pat2.'),
        verified: false,
      );
      expect(await candidates(unverified), isEmpty);
      expect(await candidates(otherAccount), isEmpty);
    });

    test('write nothing', () async {
      await issue(1);
      await candidates(pat);
      expect(
        await repository.participantAccountLinkRepository.listForAccount(pat),
        isEmpty,
      );
    });

    test('answer 409 without an invitation secret', () async {
      final response = await call(
        pat,
        'GET',
        '/account/link-candidates',
        withSecret: false,
      );
      expect(response.status, 409);
      expect(
        (response.json['error']! as Map)['code'],
        'invitations_not_available',
      );
    });
  });

  group('confirm', () {
    test(
      'links the pilot and moves what the guest did to the account',
      () async {
        final issued = await issue(1);
        final guest = await guestScores(issued.credential);
        expect(await attemptActors(), {guest.value});

        final linkId = await confirm(pat, _profileId(1));

        expect(await attemptActors(), {pat.value});
        expect(await redeemers(1), {pat.value});
        final stored = await repository.participantAccountLinkRepository
            .findById(id(linkId));
        expect(stored?.status, core.ParticipantLinkStatus.confirmed);
        expect(stored?.accountId, pat);
        expect(await candidates(pat), isEmpty);
      },
    );

    test('repeating it answers the same link', () async {
      await issue(1);
      final first = await confirm(pat, _profileId(1));
      expect(await confirm(pat, _profileId(1)), first);
      expect(
        await repository.participantAccountLinkRepository.listForAccount(pat),
        hasLength(1),
      );
    });

    test('is 404 for an id that is not the caller\'s candidate', () async {
      await issue(1);
      await issue(2);
      for (final path in [
        '/account/link-candidates/${cid(pat, _profileId(2))}/confirm', // other email
        '/account/link-candidates/${_profileId(1)}/confirm', // the profile id itself
        '/account/link-candidates/${core.Id.create().value}/confirm',
        '/account/link-candidates/not-an-id/confirm',
      ]) {
        final response = await call(pat, 'POST', path);
        expect(response.status, 404, reason: path);
        expect((response.json['error']! as Map)['code'], 'link_not_found');
      }
      final foreign = await call(
        otherAccount,
        'POST',
        '/account/link-candidates/${cid(pat, _profileId(1))}/confirm',
      );
      expect(
        foreign.status,
        404,
        reason: 'Pat\'s candidate id is no use to Sam',
      );
      expect(
        await repository.participantAccountLinkRepository.listForAccount(pat),
        isEmpty,
      );
    });

    test(
      'is 409 already_linked when another account holds the pilot',
      () async {
        await issue(1);
        await links.linkFromDirectory(
          profileId: id(_profileId(1)),
          accountId: otherAccount,
          directorAccountId: api.director,
        );

        final response = await call(
          pat,
          'POST',
          '/account/link-candidates/${cid(pat, _profileId(1))}/confirm',
        );

        expect(response.status, 409);
        expect((response.json['error']! as Map)['code'], 'already_linked');
        expect(response.text, isNot(contains(otherAccount.value)));
        expect(
          (await repository.participantAccountLinkRepository
                  .findConfirmedForProfile(id(_profileId(1))))
              ?.accountId,
          otherAccount,
        );
      },
    );
  });

  group('another account holds the pilot', () {
    setUp(() async {
      await issue(1);
      await links.linkFromDirectory(
        profileId: id(_profileId(1)),
        accountId: otherAccount,
        directorAccountId: api.director,
      );
    });

    test('the candidate is no longer listed', () async {
      expect(await candidates(pat), isEmpty);
    });

    test('declining it is 204 and leaves the holder\'s link alone', () async {
      final response = await call(
        pat,
        'POST',
        '/account/link-candidates/${cid(pat, _profileId(1))}/decline',
      );

      expect(response.status, 204);
      expect(
        (await repository.participantAccountLinkRepository
                .findConfirmedForProfile(id(_profileId(1))))
            ?.accountId,
        otherAccount,
      );
      expect(
        (await call(otherAccount, 'GET', '/account/links')).json['links'],
        hasLength(1),
      );
    });
  });

  group('a stale candidate', () {
    test('cannot be confirmed once its invitation stops opening', () async {
      await issue(1);
      final path =
          '/account/link-candidates/${cid(pat, _profileId(1))}/confirm';
      await setLifecycle(core.LifecycleState.created);

      final response = await call(pat, 'POST', path);

      expect(response.status, 404);
      expect((response.json['error']! as Map)['code'], 'link_not_found');
      expect(
        await repository.participantAccountLinkRepository.listForAccount(pat),
        isEmpty,
      );
    });
  });

  group('decline', () {
    test('answers 204, is not offered again and repeats as a no-op', () async {
      await issue(1);
      final path =
          '/account/link-candidates/${cid(pat, _profileId(1))}/decline';

      expect((await call(pat, 'POST', path)).status, 204);
      expect(await candidates(pat), isEmpty);
      expect((await call(pat, 'POST', path)).status, 204);
      final confirmAfter = await call(
        pat,
        'POST',
        '/account/link-candidates/${cid(pat, _profileId(1))}/confirm',
      );
      expect(confirmAfter.status, 404);
      expect(
        await repository.participantAccountLinkRepository.listForAccount(pat),
        hasLength(1),
      );
    });

    test('is 404 for something that is not a candidate', () async {
      await issue(1);
      final response = await call(
        otherAccount,
        'POST',
        '/account/link-candidates/${cid(pat, _profileId(1))}/decline',
      );
      expect(response.status, 404);
    });
  });

  group('participations', () {
    test('list the linked pilot\'s contests and drop them on unlink', () async {
      await issue(1);
      expect(await participations(pat), isEmpty, reason: 'not linked yet');
      final linkId = await confirm(pat, _profileId(1));

      final response = await call(pat, 'GET', '/account/participations');

      expect(response.status, 200, reason: response.text);
      final row =
          (response.json['participations']! as List<Object?>).single!
              as Map<String, Object?>;
      expect(row['participation_id'], _participationId(1));
      expect(row['contest_id'], _contestId);
      expect(row['contest_name'], 'Spring Open');
      expect(row['timezone'], 'America/Denver');
      expect(row['start_date'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(row['end_date'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(row['phase'], 'invited', reason: 'scoring is open, not running');
      expect(row['read_only'], false);
      expect(response.text, isNot(contains(api.director.value)));
      expect(response.text.toLowerCase(), isNot(contains(_email)));

      expect(
        (await call(pat, 'POST', '/account/links/$linkId/end')).status,
        200,
      );
      expect(await participations(pat), isEmpty);
    });

    test('follow the contest to completed, read only', () async {
      await issue(1);
      await confirm(pat, _profileId(1));
      await setLifecycle(core.LifecycleState.running);
      final running =
          (await participations(pat)).single! as Map<String, Object?>;
      expect(running['phase'], 'in_progress');
      expect(running['read_only'], false);

      await setLifecycle(core.LifecycleState.completed);
      final row = (await participations(pat)).single! as Map<String, Object?>;

      expect(row['phase'], 'completed');
      expect(row['read_only'], true);
    });

    test(
      'carry the public results address only for a public contest',
      () async {
        await issue(1);
        await confirm(pat, _profileId(1));
        Future<Object?> address() async =>
            ((await participations(pat)).single! as Map)['public_results_url'];
        expect(await address(), isNull, reason: 'never published');

        final publicationId = core.Id.create();
        Future<void> publication(core.PublicationVisibility visibility) =>
            repository.publicationIdentityRepository
                .save(
                  core.PublicationIdentity(
                    id: publicationId,
                    contestId: id(_contestId),
                    verificationEmail: 'director@example.com',
                    visibility: visibility,
                    publishedAt: clock,
                    contestStartsAt: clock,
                  ),
                )
                .then((_) {});

        await publication(core.PublicationVisibility.unlisted);
        expect(await address(), isNull, reason: 'unlisted is not public');

        final saved = await repository.publicationIdentityRepository.findById(
          publicationId,
        );
        await repository.publicationIdentityRepository.save(
          core.PublicationIdentity(
            id: publicationId,
            contestId: id(_contestId),
            verificationEmail: 'director@example.com',
            visibility: core.PublicationVisibility.public,
            publishedAt: clock,
            contestStartsAt: clock,
            revision: saved!.revision,
          ),
        );
        expect(
          await address(),
          'https://rcsoarscore.com/results/contests/${publicationId.value}',
        );
      },
    );

    test('still list a contest whose stored time zone is unknown', () async {
      await issue(1);
      await confirm(pat, _profileId(1));
      final contest = await repository.contestRepository.findById(
        id(_contestId),
      );
      await repository.contestRepository.save(
        core.Contest.fromJson({...contest!.toJson(), 'timezone': 'Not/AZone'}),
        metadata: core.MutationMetadata(
          clientMutationId: 'legacy-zone',
          authority: core.Authority.director,
          clientTime: clock,
          actorId: api.director,
        ),
      );

      final row = (await participations(pat)).single! as Map<String, Object?>;

      expect(row['timezone'], 'Not/AZone');
      expect(row['start_date'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });

    test('are empty for an account with no link', () async {
      await issue(1);
      expect(await participations(otherAccount), isEmpty);
    });

    test('every route is 409 without an invitation secret', () async {
      for (final (method, path) in [
        ('POST', '/account/link-candidates/${core.Id.create().value}/confirm'),
        ('POST', '/account/link-candidates/${core.Id.create().value}/decline'),
        ('GET', '/account/links'),
        ('POST', '/account/links/${core.Id.create().value}/end'),
      ]) {
        final response = await call(pat, method, path, withSecret: false);
        expect(response.status, 409, reason: '$method $path');
        expect(
          (response.json['error']! as Map)['code'],
          'invitations_not_available',
        );
      }
    });

    test('are 409 without an invitation secret', () async {
      final response = await call(
        pat,
        'GET',
        '/account/participations',
        withSecret: false,
      );
      expect(response.status, 409);
    });
  });

  group('links', () {
    test('lists the confirmed link by pilot name, without an email', () async {
      await issue(1);
      final linkId = await confirm(pat, _profileId(1));

      final response = await call(pat, 'GET', '/account/links');

      expect(response.status, 200, reason: response.text);
      final link =
          (response.json['links']! as List<Object?>).single!
              as Map<String, Object?>;
      expect(link['id'], linkId);
      expect(link['pilot_name'], 'Pilot1 Rivera');
      expect(link['status'], 'Confirmed');
      expect(link['origin'], 'EmailMatch');
      expect(response.text.toLowerCase(), isNot(contains(_email)));
      expect(
        (await call(otherAccount, 'GET', '/account/links')).json['links'],
        isEmpty,
      );
    });

    test(
      'end one: Ended, repeatable, and the link opens anonymously',
      () async {
        final issued = await issue(1);
        final guest = await guestScores(issued.credential);
        final linkId = await confirm(pat, _profileId(1));

        final ended = await call(pat, 'POST', '/account/links/$linkId/end');

        expect(ended.status, 200, reason: ended.text);
        expect(ended.json['status'], 'Ended');
        expect(ended.json['ended_at'], isNotNull);
        expect(await redeemers(1), {guest.value}, reason: 'back to the guest');
        expect(await attemptActors(), {pat.value}, reason: 'attempts stay');
        expect(
          (await call(pat, 'GET', '/account/links')).json['links'],
          isEmpty,
        );
        final again = await call(pat, 'POST', '/account/links/$linkId/end');
        expect(again.status, 200);
        expect(again.json['status'], 'Ended');
        // The pilot can still open their own link as a guest.
        final reopened = await invitations.resolve(issued.credential);
        expect(reopened.access.guestAccountId, guest);
      },
    );

    test('ending another account\'s link or a bad id is 404', () async {
      await issue(1);
      final linkId = await confirm(pat, _profileId(1));

      for (final path in [
        '/account/links/$linkId/end', // as Sam, below
        '/account/links/${core.Id.create().value}/end',
        '/account/links/not-an-id/end',
      ]) {
        final response = await call(otherAccount, 'POST', path);
        expect(response.status, 404, reason: path);
        expect((response.json['error']! as Map)['code'], 'link_not_found');
      }
      expect(
        (await repository.participantAccountLinkRepository.findById(id(linkId)))
            ?.status,
        core.ParticipantLinkStatus.confirmed,
      );
    });
  });
}
