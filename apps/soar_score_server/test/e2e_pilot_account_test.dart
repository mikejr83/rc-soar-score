import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_server/handler.dart';
import 'package:test/test.dart';

import '../tool/e2e_pilot_account.dart';
import 'api_slice/slice_client.dart';

const _contestId = '019c0000-0000-7000-8000-000000000046';
const _profileId = '019c0000-0000-7000-8000-00000000c101';
const _participationId = '019c0000-0000-7000-8000-00000000d201';
const _secret = 'a-test-secret-that-is-at-least-32-bytes-long';

/// The E2E server's pilot account (the `Bearer e2e-pilot` principal and the
/// `/__e2e/pilot-account-link` seed) over a real database, as the signed-in
/// self-scoring journey uses them.
void main() {
  late SliceClient api;
  late Repository repository;
  late core.InvitationService invitations;
  late core.Id pilot;
  late Handler handler;

  setUp(() async {
    api = await SliceClient.open(SliceBackend.sqlite);
    repository = Repository(api.database);
    invitations = core.InvitationService(
      repository,
      core.InvitationCodec.fromText(_secret),
    );
    pilot = await seedE2ePilotAccount(repository);
    final api0 = createServerHandler(
      api.database,
      authMiddleware: e2ePrincipal(director: api.director, pilot: pilot),
      invitationSecret: _secret,
    );
    handler = const Pipeline()
        .addMiddleware(
          e2ePilotAccountLink(repository, invitations, pilot: pilot),
        )
        .addHandler(api0);

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
    await api.expectOk(
      'POST',
      '/participants',
      status: 201,
      body: {
        'id': _profileId,
        'first_name': 'Peggy',
        'last_name': 'Rivera',
        // Not the pilot account's address: the seed sets it.
        'email': 'someone.else@example.com',
      },
    );
    await api.expectOk(
      'POST',
      '/contests/$_contestId/participations',
      status: 201,
      body: {
        'id': _participationId,
        'participant_profile_id': _profileId,
        'role_id': core.SystemRoles.pilotId.value,
      },
    );
    await api.expectOk(
      'POST',
      '/contests/$_contestId/matrix/draws',
      status: 201,
      body: {
        'id': '019c0000-0000-7000-8000-000000000547',
        'rounds': 1,
        'groups_per_round': 1,
        'random_seed': 7,
      },
    );
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
  });
  tearDown(() => api.close());

  Future<Response> send(
    String method,
    String path, {
    bool asPilot = true,
    Object? body,
  }) async => handler(
    Request(
      method,
      Uri.parse('http://localhost$path'),
      body: body == null ? null : jsonEncode(body),
      headers: {if (asPilot) 'authorization': 'Bearer $e2ePilotToken'},
    ),
  );

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await send('GET', path);
    final text = await response.readAsString();
    expect(response.statusCode, 200, reason: text);
    return jsonDecode(text) as Map<String, dynamic>;
  }

  Future<Response> seed(String state) => send(
    'POST',
    '/__e2e/pilot-account-link',
    asPilot: false,
    body: {'participation_id': _participationId, 'state': state},
  );

  Future<void> invite() => invitations
      .issue(
        contestId: core.Id.parse(_contestId),
        participationId: core.Id.parse(_participationId),
        issuedBy: api.director,
        clientMutationId: 'issue-1',
      )
      .then((_) {});

  test('a request acts as the pilot only with the pilot token', () async {
    expect((await getJson('/api/v1/account'))['account_id'], pilot.value);
    final director = await send('GET', '/api/v1/account', asPilot: false);
    expect(
      jsonDecode(await director.readAsString())['account_id'],
      api.director.value,
    );
  });

  test('the pilot starts with no contests and no candidates', () async {
    await invite();
    expect(
      (await getJson('/api/v1/account/participations'))['participations'],
      isEmpty,
    );
    expect(
      (await getJson('/api/v1/account/link-candidates'))['candidates'],
      isEmpty,
    );
  });

  test('candidate offers the profile and links nothing', () async {
    await invite();
    final response = await seed('candidate');
    expect(response.statusCode, 200, reason: await response.readAsString());
    final candidates =
        (await getJson('/api/v1/account/link-candidates'))['candidates']
            as List;
    expect(candidates, hasLength(1));
    expect((candidates.single as Map)['first_name'], 'Peggy');
    expect(
      (await getJson('/api/v1/account/participations'))['participations'],
      isEmpty,
    );
    // Repeating it changes nothing.
    expect((await seed('candidate')).statusCode, 200);
  });

  test('confirmed lists the contest and leaves no candidate', () async {
    await invite();
    final response = await seed('confirmed');
    final text = await response.readAsString();
    expect(response.statusCode, 200, reason: text);
    expect(jsonDecode(text), {
      'account_id': pilot.value,
      'profile_id': _profileId,
    });
    final rows =
        (await getJson('/api/v1/account/participations'))['participations']
            as List;
    expect((rows.single as Map)['contest_name'], 'Spring Open');
    expect(
      (await getJson('/api/v1/account/link-candidates'))['candidates'],
      isEmpty,
    );
    expect((await seed('confirmed')).statusCode, 200);
  });

  test('a participation with no invitation is refused', () async {
    for (final state in ['candidate', 'confirmed']) {
      final response = await seed(state);
      expect(response.statusCode, 409, reason: state);
      expect(await response.readAsString(), startsWith('link_not_found'));
    }
  });

  test('an unknown state or participation is refused', () async {
    expect((await seed('linked')).statusCode, 400);
    final unknown = await send(
      'POST',
      '/__e2e/pilot-account-link',
      asPilot: false,
      body: {
        'participation_id': '019c0000-0000-7000-8000-00000000d299',
        'state': 'candidate',
      },
    );
    expect(unknown.statusCode, 404);
  });
}
