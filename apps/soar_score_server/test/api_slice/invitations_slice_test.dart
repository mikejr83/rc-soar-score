import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_server/handler.dart';
import 'package:test/test.dart';

import 'slice_client.dart';

const _contestId = '019c0000-0000-7000-8000-000000000020';
const _profileId = '019c0000-0000-7000-8000-000000000101';
const _participationId = '019c0000-0000-7000-8000-000000000201';
const _otherProfileId = '019c0000-0000-7000-8000-000000000102';
const _otherParticipationId = '019c0000-0000-7000-8000-000000000202';
const _secret = 'a-test-secret-that-is-at-least-32-bytes-long';

/// Invitation links and the guest session over a real database, the way the
/// self-scoring app calls them: JSON over `/self-scoring`, no sign-in.
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
  late core.InvitationService service;
  late Handler handler;
  var clock = DateTime.now().toUtc();

  setUp(() async {
    clock = DateTime.now().toUtc();
    api = await SliceClient.open(backend);
    repository = Repository(api.database);
    service = core.InvitationService(
      repository,
      core.InvitationCodec.fromText(_secret),
      clock: () => clock,
    );
    handler = createServerHandler(
      api.database,
      authMiddleware: fixedPrincipal(Principal(accountId: api.director)),
      invitationSecret: _secret,
    );
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
  });
  tearDown(() => api.close());

  Future<void> configureAndAddPilots() async {
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
    for (final (profile, participation, first) in [
      (_profileId, _participationId, 'Alex'),
      (_otherProfileId, _otherParticipationId, 'Blake'),
    ]) {
      await api.expectOk(
        'POST',
        '/participants',
        status: 201,
        body: {'id': profile, 'first_name': first, 'last_name': 'Rivera'},
      );
      await api.expectOk(
        'POST',
        '/contests/$_contestId/participations',
        status: 201,
        body: {
          'id': participation,
          'participant_profile_id': profile,
          'role_id': core.SystemRoles.pilotId.value,
        },
      );
    }
  }

  Future<core.IssuedInvitation> issue([
    String participation = _participationId,
    String mutation = 'issue-1',
  ]) => service.issue(
    contestId: core.Id.parse(_contestId),
    participationId: core.Id.parse(participation),
    issuedBy: api.director,
    clientMutationId: mutation,
  );

  Future<(int, Map<String, Object?>)> call(
    String method,
    String path, {
    Object? body,
    String? token,
  }) async {
    final response = await handler(
      Request(
        method,
        Uri.parse('http://localhost/api/v1/self-scoring$path'),
        body: body == null ? null : jsonEncode(body),
        headers: {if (token != null) 'authorization': 'Bearer $token'},
      ),
    );
    final text = await response.readAsString();
    return (
      response.statusCode,
      text.isEmpty
          ? <String, Object?>{}
          : jsonDecode(text) as Map<String, Object?>,
    );
  }

  Future<(int, Map<String, Object?>)> resolve(String credential) =>
      call('POST', '/invitations/resolve', body: {'credential': credential});

  test(
    'issuing for a participation that is not there is a not-found',
    () async {
      await expectLater(issue(), throwsA(isA<core.EntityNotFoundError>()));
    },
  );

  test('issuing is idempotent and the link stays the same', () async {
    await configureAndAddPilots();
    final first = await issue();
    expect(first.created, isTrue);
    expect(first.invitation.invitationRevision, 1);
    expect(first.credential.length, greaterThan(40));

    final retry = await issue();
    final another = await issue(_participationId, 'issue-2');
    for (final again in [retry, another]) {
      expect(again.created, isFalse);
      expect(again.invitation.id, first.invitation.id);
      expect(again.credential, first.credential);
    }
    expect(
      await repository.invitationRepository.listForContest(
        core.Id.parse(_contestId),
      ),
      hasLength(1),
    );
    final blake = await issue(_otherParticipationId, 'issue-3');
    expect(blake.credential, isNot(first.credential));
  });

  test('concurrent issues agree on one link and never fail', () async {
    await configureAndAddPilots();
    final sameMutation = await Future.wait([
      for (var i = 0; i < 5; i++) issue(),
    ]);
    final differentMutations = await Future.wait([
      for (var i = 0; i < 5; i++) issue(_otherParticipationId, 'other-$i'),
    ]);
    for (final results in [sameMutation, differentMutations]) {
      expect({for (final r in results) r.credential}, hasLength(1));
      expect({for (final r in results) r.invitation.id}, hasLength(1));
      expect(results.where((r) => r.created), hasLength(1));
    }
    final all = await repository.invitationRepository.listForContest(
      core.Id.parse(_contestId),
    );
    expect(all, hasLength(2));
    expect(all.where((i) => i.isActive), hasLength(2));
  });

  test('concurrent first opens make one guest and valid sessions', () async {
    await configureAndAddPilots();
    final issued = await issue();
    final resolutions = await Future.wait([
      for (var i = 0; i < 6; i++) service.resolve(issued.credential),
    ]);
    expect({
      for (final r in resolutions) r.access.guestAccountId,
    }, hasLength(1));
    final stored = (await repository.invitationRepository.findById(
      issued.invitation.id,
    ))!;
    expect(stored.redeemedByAccountId, resolutions.first.access.guestAccountId);
    for (final r in resolutions) {
      final access = await service.authorize(r.sessionToken);
      expect(access.guestAccountId, stored.redeemedByAccountId);
    }
  });

  test('no audit event carries a credential or its hash', () async {
    await configureAndAddPilots();
    final issued = await issue();
    await resolve(issued.credential);
    await resolve('${issued.credential.split('.').first}.${'A' * 32}');
    final stored = (await repository.invitationRepository.findById(
      issued.invitation.id,
    ))!;
    final events = await repository.auditEventRepository.listForContest(
      core.Id.parse(_contestId),
    );
    final text = jsonEncode([for (final e in events) e.toJson()]);
    expect(text, isNot(contains(issued.credential)));
    expect(text, isNot(contains(issued.credential.split('.').last)));
    expect(text, isNot(contains(stored.protectedCredential.value)));
  });

  test('the raw credential is never stored', () async {
    await configureAndAddPilots();
    final issued = await issue();
    final stored = (await repository.invitationRepository.findById(
      issued.invitation.id,
    ))!;
    expect(
      stored.protectedCredential.value,
      isNot(contains(issued.credential)),
    );
    expect(stored.protectedCredential.value, startsWith('sha256:'));
  });

  test(
    'opening the link gives a guest session, the same one each time',
    () async {
      await configureAndAddPilots();
      final issued = await issue();

      final (status, body) = await resolve(issued.credential);
      expect(status, 200, reason: '$body');
      final contest = body['contest']! as Map;
      final participant = body['participant']! as Map;
      expect(contest['contest_id'], _contestId);
      expect(contest['name'], 'Spring Open');
      expect(contest['discipline_type'], 'F5J');
      expect(participant['participation_id'], _participationId);
      expect(participant['pilot_name'], 'Alex Rivera');
      expect(participant['role'], 'pilot');
      final token = body['session_token']! as String;

      final (againStatus, again) = await resolve(issued.credential);
      expect(againStatus, 200);
      expect(again['participant'], participant);

      final stored = (await repository.invitationRepository.findById(
        issued.invitation.id,
      ))!;
      expect(stored.firstUsedAt, isNotNull);
      expect(stored.redeemedByAccountId, isNotNull);
      final guest = (await repository.accountRepository.findById(
        stored.redeemedByAccountId!,
      ))!;
      expect(guest.kind, core.AccountKind.guest);
      expect(guest.emailVerified, isFalse);

      final (sessionStatus, session) = await call(
        'GET',
        '/session',
        token: token,
      );
      expect(sessionStatus, 200, reason: '$session');
      expect(
        (session['participant']! as Map)['participation_id'],
        _participationId,
      );

      // Both opens used the same guest: one guest account for the link.
      final events = await repository.auditEventRepository.listForContest(
        core.Id.parse(_contestId),
      );
      expect(
        events.where((e) => e.action == core.AuditAction.invitationIssued),
        hasLength(1),
      );
      expect(
        events.where((e) => e.action == core.AuditAction.invitationAccessed),
        hasLength(2),
      );
    },
  );

  test('every link that does not open answers the same', () async {
    await configureAndAddPilots();
    final issued = await issue();
    final id = issued.credential.split('.').first;
    final tampered = '$id.${'A' * 32}';
    final unknown = '${core.Id.create().value}.${'A' * 32}';
    final answers = <String>{};
    for (final credential in [
      tampered,
      unknown,
      'garbage',
      '${issued.credential}x',
      id,
    ]) {
      final (status, body) = await resolve(credential);
      expect(status, 404, reason: credential);
      final error = Map<String, Object?>.of(
        (body['error']! as Map).cast<String, Object?>(),
      )..remove('requestId');
      answers.add(jsonEncode(error));
    }
    expect(answers, hasLength(1));
    expect(answers.single, contains('invalid_invitation'));

    // A replaced invitation looks the same too.
    final stored = (await repository.invitationRepository.findById(
      issued.invitation.id,
    ))!;
    await repository.invitationRepository.save(
      core.Invitation(
        id: stored.id,
        contestId: stored.contestId,
        contestParticipationId: stored.contestParticipationId,
        protectedCredential: stored.protectedCredential,
        state: core.InvitationState.replaced,
        issuedBy: stored.issuedBy,
        issuedAt: stored.issuedAt,
        clientMutationId: stored.clientMutationId,
      ),
    );
    final (status, body) = await resolve(issued.credential);
    expect(status, 404);
    final error = Map<String, Object?>.of(
      (body['error']! as Map).cast<String, Object?>(),
    )..remove('requestId');
    expect(jsonEncode(error), answers.single);
  });

  test('a replaced invitation ends a session already in hand', () async {
    await configureAndAddPilots();
    final issued = await issue();
    final (_, body) = await resolve(issued.credential);
    final token = body['session_token']! as String;
    expect((await call('GET', '/session', token: token)).$1, 200);

    final stored = (await repository.invitationRepository.findById(
      issued.invitation.id,
    ))!;
    await repository.invitationRepository.save(
      core.Invitation(
        id: stored.id,
        contestId: stored.contestId,
        contestParticipationId: stored.contestParticipationId,
        protectedCredential: stored.protectedCredential,
        state: core.InvitationState.replaced,
        issuedBy: stored.issuedBy,
        issuedAt: stored.issuedAt,
        firstUsedAt: stored.firstUsedAt,
        lastUsedAt: stored.lastUsedAt,
        redeemedByAccountId: stored.redeemedByAccountId,
        clientMutationId: stored.clientMutationId,
      ),
    );
    final (status, answer) = await call('GET', '/session', token: token);
    expect(status, 401);
    expect((answer['error']! as Map)['code'], 'session_invalid');
  });

  test('the web app keeps the session in a cookie, not the body', () async {
    await configureAndAddPilots();
    final issued = await issue();
    Future<Response> send(
      String method,
      String path, {
      Map<String, String> headers = const {},
      Object? body,
    }) async => handler(
      Request(
        method,
        Uri.parse('http://localhost/api/v1/self-scoring$path'),
        body: body == null ? null : jsonEncode(body),
        headers: headers,
      ),
    );

    final resolved = await send(
      'POST',
      '/invitations/resolve',
      headers: {'x-requested-with': 'soar-score-self-score'},
      body: {'credential': issued.credential},
    );
    expect(resolved.statusCode, 200);
    final json = jsonDecode(await resolved.readAsString()) as Map;
    expect(json['session_token'], isNull);
    expect(json['session_expires_at'], isNotNull);
    final setCookie = resolved.headers['set-cookie']!;
    expect(
      setCookie,
      allOf(
        startsWith('__Host-soar_guest='),
        contains('Secure'),
        contains('HttpOnly'),
        contains('SameSite=Lax'),
        contains('Path=/'),
        isNot(contains('Domain')),
      ),
    );
    final cookie = setCookie.split(';').first;

    final session = await send('GET', '/session', headers: {'cookie': cookie});
    expect(session.statusCode, 200);

    // A write on the cookie needs the web app's header.
    final forged = await send(
      'POST',
      '/session/end',
      headers: {'cookie': cookie},
    );
    expect(forged.statusCode, 403);
    final ended = await send(
      'POST',
      '/session/end',
      headers: {'cookie': cookie, 'x-requested-with': 'soar-score-self-score'},
    );
    expect(ended.statusCode, 204);
    expect(ended.headers['set-cookie'], contains('Max-Age=0'));

    // A dead cookie is a 401 that also clears it.
    final dead = await send(
      'GET',
      '/session',
      headers: {'cookie': '__Host-soar_guest=garbage'},
    );
    expect(dead.statusCode, 401);
    expect(dead.headers['set-cookie'], contains('Max-Age=0'));

    // The same resolve without the header returns the token, no cookie.
    final native = await send(
      'POST',
      '/invitations/resolve',
      body: {'credential': issued.credential},
    );
    expect(native.headers['set-cookie'], isNull);
    expect(
      (jsonDecode(await native.readAsString()) as Map)['session_token'],
      isA<String>(),
    );
  });

  test('a session needs a valid token', () async {
    await configureAndAddPilots();
    final issued = await issue();
    final (_, body) = await resolve(issued.credential);
    final token = body['session_token']! as String;

    for (final bad in [
      null,
      'nonsense',
      '$token.extra',
      '${token}x',
      issued.credential,
    ]) {
      expect(
        (await call('GET', '/session', token: bad)).$1,
        401,
        reason: '$bad',
      );
    }
    final dot = token.indexOf('.');
    final forged = base64Url
        .encode(
          utf8.encode(
            jsonEncode({
              ...(jsonDecode(
                utf8.decode(
                  base64Url.decode(
                    base64Url.normalize(token.substring(0, dot)),
                  ),
                ),
              ) as Map).cast<String, Object?>(),
              'part': _otherParticipationId,
            }),
          ),
        )
        .replaceAll('=', '');
    expect(
      (await call(
        'GET',
        '/session',
        token: '$forged${token.substring(dot)}',
      )).$1,
      401,
    );
  });

  test('a guest session is not a director', () async {
    await configureAndAddPilots();
    final issued = await issue();
    final (_, body) = await resolve(issued.credential);
    final token = body['session_token']! as String;
    // The /api/v1 routes want the account sign-in; a guest token is no
    // account token (the server's own auth layer refuses it).
    final api401 = createServerHandler(
      api.database,
      authMiddleware: (inner) =>
          (request) => Response(401),
      invitationSecret: _secret,
    );
    final response = await api401(
      Request(
        'GET',
        Uri.parse('http://localhost/api/v1/contests/$_contestId'),
        headers: {'authorization': 'Bearer $token'},
      ),
    );
    expect(response.statusCode, 401);
  });

  test('writes need scoring open and the contest not locked', () async {
    await configureAndAddPilots();
    final issued = await issue();
    final (_, body) = await resolve(issued.credential);
    final token = body['session_token']! as String;

    expect((await service.authorize(token)).readOnly, isFalse);
    Future<String> writeError() async {
      try {
        await service.authorize(token, write: true);
      } on core.ContestStateError catch (e) {
        return e.code;
      }
      return 'allowed';
    }

    expect(await writeError(), 'scoring_closed');
    await api.expectOk(
      'POST',
      '/contests/$_contestId/actions',
      body: {
        'action': 'openScoring',
        'base_revision': (await api.expectOk(
          'GET',
          '/contests/$_contestId',
        ))['revision'],
      },
    );
    expect(await writeError(), 'allowed');
    await api.expectOk(
      'POST',
      '/contests/$_contestId/actions',
      body: {
        'action': 'lock',
        'base_revision': (await api.expectOk(
          'GET',
          '/contests/$_contestId',
        ))['revision'],
      },
    );
    expect(await writeError(), 'scoring_closed');
  });

  test('after completion the link is read-only for 24 hours', () async {
    await configureAndAddPilots();
    final issued = await issue();
    await api.expectOk(
      'POST',
      '/contests/$_contestId/actions',
      body: {
        'action': 'openScoring',
        'base_revision': (await api.expectOk(
          'GET',
          '/contests/$_contestId',
        ))['revision'],
      },
    );
    final contest = await repository.contestRepository.findById(
      core.Id.parse(_contestId),
    );
    // Completion needs a Running contest; set the state directly.
    await repository.contestRepository.save(
      contest!.copyWithState(
        lifecycleState: core.LifecycleState.completed,
        scoringAccess: core.ScoringAccess.closed,
        updatedAt: clock,
      ),
      metadata: core.MutationMetadata(
        clientMutationId: 'complete',
        authority: core.Authority.director,
        clientTime: clock,
        actorId: api.director,
      ),
    );

    final resolution = await service.resolve(issued.credential);
    expect(resolution.access.readOnly, isTrue);
    await expectLater(
      service.authorize(resolution.sessionToken, write: true),
      throwsA(isA<core.ContestStateError>()),
    );

    clock = clock.add(const Duration(hours: 23));
    await service.authorize(resolution.sessionToken);
    clock = clock.add(const Duration(hours: 2));
    await expectLater(
      service.authorize(resolution.sessionToken),
      throwsA(isA<core.InvitationAccessError>()),
    );
    await expectLater(
      service.resolve(issued.credential),
      throwsA(isA<core.InvitationAccessError>()),
    );
  });
}
