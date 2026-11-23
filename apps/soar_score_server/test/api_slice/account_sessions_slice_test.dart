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

/// The invitation claim and open-from-list routes (#545 C) over a real
/// database: a signed-in pilot opens a link or a contest of their list and
/// gets a session acting as their account, which ends with the link.
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
  late int matrixRevision;
  final handlers = <String, Handler>{};
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
    handlers.clear();
    api = await SliceClient.open(backend);
    repository = Repository(api.database);
    invitations = core.InvitationService(
      repository,
      core.InvitationCodec.fromText(_secret),
      clock: () => clock,
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

  /// A request to the server as [as] (or anonymously, with [as] null).
  Future<
    ({
      int status,
      Map<String, Object?> json,
      String text,
      Map<String, String> headers,
    })
  >
  send(
    core.Id? as,
    String method,
    String path, {
    Object? body,
    Map<String, String> headers = const {},
    String? secret = _secret,
    InvitationThrottle? throttle,
  }) async {
    final key = '${as?.value}/$secret/${identityHashCode(throttle)}';
    final handler = handlers.putIfAbsent(
      key,
      () => createServerHandler(
        api.database,
        authMiddleware: fixedPrincipal(
          Principal(accountId: as ?? api.director),
        ),
        invitationSecret: secret,
        invitationThrottle: throttle,
      ),
    );
    final response = await handler(
      Request(
        method,
        Uri.parse('http://localhost/api/v1$path'),
        body: body == null ? null : jsonEncode(body),
        headers: headers,
      ),
    );
    final text = await response.readAsString();
    return (
      status: response.statusCode,
      json: text.isEmpty
          ? const <String, Object?>{}
          : jsonDecode(text) as Map<String, Object?>,
      text: text,
      headers: response.headers,
    );
  }

  Future<String> claim(core.Id as, String credential) async {
    final response = await send(
      as,
      'POST',
      '/account/invitation-claims',
      body: {'credential': credential},
    );
    expect(response.status, 200, reason: response.text);
    return response.json['session_token']! as String;
  }

  Map<String, String> bearer(String token) => {
    'authorization': 'Bearer $token',
  };

  Future<int> overviewStatus(String token) async => (await send(
    null,
    'GET',
    '/self-scoring/overview',
    headers: bearer(token),
  )).status;

  Future<int> submit(String token, int round, String mutation) async {
    final response = await send(
      null,
      'POST',
      '/self-scoring/rounds/$round/scores',
      headers: bearer(token),
      body: {
        'client_mutation_id': mutation,
        'matrix_revision': matrixRevision,
        'components': _goodScore,
      },
    );
    return response.status;
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

  Future<core.Id> guestScores(String credential) async {
    final resolved = await invitations.resolve(credential);
    expect(await submit(resolved.sessionToken, 1, 'guest-1'), 201);
    return resolved.access.guestAccountId;
  }

  Future<String> confirmByEmail(core.Id as, String profile) async {
    final candidate = invitations.codec
        .candidateIdFor(accountId: as, profileId: id(profile))
        .value;
    final response = await send(
      as,
      'POST',
      '/account/link-candidates/$candidate/confirm',
    );
    expect(response.status, 200, reason: response.text);
    return response.json['id']! as String;
  }

  group('claiming an invitation link while signed in', () {
    test('links the pilot, claims the guest and acts as the account', () async {
      final issued = await issue(1);
      final guest = await guestScores(issued.credential);
      final guestSession = (await invitations.resolve(issued.credential))
          .sessionToken;
      expect(await attemptActors(), {guest.value});

      final token = await claim(otherAccount, issued.credential);

      // The email need not match: the director's invitation names the pilot.
      final stored = await repository.participantAccountLinkRepository
          .listForAccount(otherAccount);
      expect(stored.single.isConfirmed, isTrue);
      expect(
        stored.single.origin,
        core.ParticipantLinkOrigin.invitationRedemption,
      );
      expect(await attemptActors(), {otherAccount.value});
      expect(await redeemers(1), {otherAccount.value});
      expect(await overviewStatus(token), 200);
      expect(await submit(token, 2, 'account-2'), 201);
      expect(await attemptActors(), {otherAccount.value});
      expect(
        await overviewStatus(guestSession),
        401,
        reason: 'the guest session ended with the claim',
      );
    });

    test('a pilot who never opened the link gets the session too', () async {
      final issued = await issue(1);

      final token = await claim(pat, issued.credential);

      expect(await redeemers(1), {pat.value});
      expect(await submit(token, 1, 'account-1'), 201);
      expect(await attemptActors(), {pat.value});
    });

    test('repeating it is a no-op that gives a new session', () async {
      final issued = await issue(1);
      final first = await claim(pat, issued.credential);
      final second = await claim(pat, issued.credential);

      expect(
        await repository.participantAccountLinkRepository.listForAccount(pat),
        hasLength(1),
      );
      expect(await overviewStatus(first), 200);
      expect(await overviewStatus(second), 200);
    });

    test('the web app gets a cookie and no token', () async {
      final issued = await issue(1);

      final response = await send(
        pat,
        'POST',
        '/account/invitation-claims',
        body: {'credential': issued.credential},
        headers: {'x-requested-with': 'soar-score-web'},
      );

      expect(response.status, 200, reason: response.text);
      expect(response.json['session_token'], isNull);
      expect(response.headers['set-cookie'], contains('HttpOnly'));
      expect(response.headers['cache-control'], contains('no-store'));
      // The cookie carries the account's session.
      final cookie = response.headers['set-cookie']!.split(';').first;
      final overview = await send(
        null,
        'GET',
        '/self-scoring/overview',
        headers: {'cookie': cookie},
      );
      expect(overview.status, 200, reason: overview.text);
    });

    test('another account that holds the pilot gets already_linked', () async {
      final issued = await issue(1);
      final guest = await guestScores(issued.credential);
      await claim(pat, issued.credential);

      final response = await send(
        otherAccount,
        'POST',
        '/account/invitation-claims',
        body: {'credential': issued.credential},
      );

      expect(response.status, 409);
      expect((response.json['error']! as Map)['code'], 'already_linked');
      expect(response.json.toString(), isNot(contains('token')));
      expect(
        await repository.participantAccountLinkRepository.listForAccount(
          otherAccount,
        ),
        isEmpty,
      );
      expect(await attemptActors(), {pat.value});
      expect(guest, isNot(pat));
    });

    test('a link that does not open is the usual invalid link', () async {
      final anonymous = await send(
        null,
        'POST',
        '/self-scoring/invitations/resolve',
        body: {'credential': 'nonsense'},
      );
      final signedIn = await send(
        pat,
        'POST',
        '/account/invitation-claims',
        body: {'credential': 'nonsense'},
      );

      expect(signedIn.status, anonymous.status);
      expect(signedIn.status, 404);
      expect((signedIn.json['error']! as Map)['code'], 'invalid_invitation');
    });

    test('a contest that has not started is the same invalid link', () async {
      final issued = await issue(1);
      await setLifecycle(core.LifecycleState.created);

      final response = await send(
        pat,
        'POST',
        '/account/invitation-claims',
        body: {'credential': issued.credential},
      );

      expect(response.status, 404);
      expect((response.json['error']! as Map)['code'], 'invalid_invitation');
      expect(
        await repository.participantAccountLinkRepository.listForAccount(pat),
        isEmpty,
      );
    });

    test('shares the attempt limit with opening a link anonymously', () async {
      final throttle = InvitationThrottle(maxFailures: 2);
      for (var i = 0; i < 2; i++) {
        await send(
          null,
          'POST',
          '/self-scoring/invitations/resolve',
          body: {'credential': 'nonsense-$i'},
          throttle: throttle,
        );
      }

      final response = await send(
        pat,
        'POST',
        '/account/invitation-claims',
        body: {'credential': 'nonsense'},
        throttle: throttle,
      );

      expect(response.status, 429);
      expect(response.headers['retry-after'], isNotNull);
    });

    test('a body that is not a request counts as a failure', () async {
      final throttle = InvitationThrottle(maxFailures: 2);
      for (var i = 0; i < 2; i++) {
        final response = await send(
          pat,
          'POST',
          '/account/invitation-claims',
          body: {'nothing': 'here'},
          throttle: throttle,
        );
        expect(response.status, 400);
      }

      final response = await send(
        pat,
        'POST',
        '/account/invitation-claims',
        body: {'credential': 'nonsense'},
        throttle: throttle,
      );

      expect(response.status, 429);
    });

    test('is 409 without an invitation secret', () async {
      final response = await send(
        pat,
        'POST',
        '/account/invitation-claims',
        body: {'credential': 'nonsense'},
        secret: null,
      );

      expect(response.status, 409);
      expect(
        (response.json['error']! as Map)['code'],
        'invitations_not_available',
      );
    });
  });

  group('an account session', () {
    test('ends at once when the link ends, and the link opens anonymously '
        'again', () async {
      final issued = await issue(1);
      final guest = await guestScores(issued.credential);
      final token = await claim(pat, issued.credential);
      final linkId =
          (await repository.participantAccountLinkRepository.listForAccount(
            pat,
          )).single.id;
      expect(await overviewStatus(token), 200);

      final ended = await send(
        pat,
        'POST',
        '/account/links/${linkId.value}/end',
      );
      expect(ended.status, 200, reason: ended.text);

      expect(await overviewStatus(token), 401);
      expect(await submit(token, 2, 'late'), 401);
      // The pilot is not locked out of their own link.
      expect(await redeemers(1), {guest.value});
      final again = await send(
        null,
        'POST',
        '/self-scoring/invitations/resolve',
        body: {'credential': issued.credential},
      );
      expect(again.status, 200, reason: again.text);
      expect(await overviewStatus(again.json['session_token']! as String), 200);
      expect(await attemptActors(), {pat.value}, reason: 'kept by the account');
    });

    test('does not open for an account without the link', () async {
      final issued = await issue(1);
      final token = await claim(pat, issued.credential);
      // A forged-in-the-database state: the invitation names the account but
      // the link is gone.
      await api.database.customStatement(
        "UPDATE participant_account_links SET status = 'Ended', ended_at = confirmed_at",
      );

      expect(await overviewStatus(token), 401);
    });
  });

  group('opening a contest from the list', () {
    test('gives a session acting as the account', () async {
      await issue(1);
      await confirmByEmail(pat, _profileId(1));

      final response = await send(
        pat,
        'POST',
        '/account/participations/${_participationId(1)}/session',
      );

      expect(response.status, 200, reason: response.text);
      final token = response.json['session_token']! as String;
      expect(await overviewStatus(token), 200);
      expect(await submit(token, 1, 'from-list'), 201);
      expect(await attemptActors(), {pat.value});
      expect(await redeemers(1), {pat.value});
    });

    test(
      'claims a guest who opened the link after the link was made',
      () async {
        final issued = await issue(1);
        await confirmByEmail(pat, _profileId(1));
        final guest = await guestScores(issued.credential);
        expect(await attemptActors(), {guest.value});

        final response = await send(
          pat,
          'POST',
          '/account/participations/${_participationId(1)}/session',
        );

        expect(response.status, 200, reason: response.text);
        expect(await attemptActors(), {pat.value});
        expect(await redeemers(1), {pat.value});
      },
    );

    test('is 404 for a participation not on the caller\'s list', () async {
      await issue(1);
      await issue(2);
      await confirmByEmail(pat, _profileId(1));

      for (final participation in [
        _participationId(2), // another pilot's
        core.Id.create().value, // unknown
      ]) {
        final response = await send(
          pat,
          'POST',
          '/account/participations/$participation/session',
        );
        expect(response.status, 404, reason: response.text);
        expect((response.json['error']! as Map)['code'], 'link_not_found');
      }
      final badId = await send(
        pat,
        'POST',
        '/account/participations/nope/session',
      );
      expect(badId.status, 404);
    });

    test('is 404 for another account, and after the link ends', () async {
      await issue(1);
      final linkId = await confirmByEmail(pat, _profileId(1));

      final other = await send(
        otherAccount,
        'POST',
        '/account/participations/${_participationId(1)}/session',
      );
      expect(other.status, 404);

      await send(pat, 'POST', '/account/links/$linkId/end');
      final after = await send(
        pat,
        'POST',
        '/account/participations/${_participationId(1)}/session',
      );
      expect(after.status, 404);
    });

    test('is 409 without an invitation secret', () async {
      final response = await send(
        pat,
        'POST',
        '/account/participations/${_participationId(1)}/session',
        secret: null,
      );

      expect(response.status, 409);
      expect(
        (response.json['error']! as Map)['code'],
        'invitations_not_available',
      );
    });
  });
}
