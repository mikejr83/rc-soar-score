import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_server/handler.dart';
import 'package:test/test.dart';

import 'slice_client.dart';

const _contestId = '019c0000-0000-7000-8000-000000000020';
const _secret = 'a-test-secret-that-is-at-least-32-bytes-long';
const _pilots = 5;

String _profileId(int n) => '019c0000-0000-7000-8000-0000000001${_two(n)}';
String _participationId(int n) =>
    '019c0000-0000-7000-8000-0000000002${_two(n)}';
String _two(int n) => n.toString().padLeft(2, '0');

/// The participant read routes (#787) over a real database: a drawn F5J
/// contest, links for two pilots, and the pilot's overview and entry
/// context the way the self-scoring app reads them.
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
  late List<Map<String, Object?>> rounds;
  late List<Map<String, Object?>> assignments;

  setUp(() async {
    api = await SliceClient.open(backend);
    repository = Repository(api.database);
    service = core.InvitationService(
      repository,
      core.InvitationCodec.fromText(_secret),
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
    for (var n = 1; n <= _pilots; n++) {
      await api.expectOk(
        'POST',
        '/participants',
        status: 201,
        body: {
          'id': _profileId(n),
          'first_name': n == 2 ? 'Blake' : 'Pilot$n',
          'last_name': 'Rivera',
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
        'id': '019c0000-0000-7000-8000-000000000501',
        'rounds': 3,
        'groups_per_round': 2,
        'random_seed': 7,
      },
    );
    // A pilot who joins after the draw, for the late-add cases.
    await api.expectOk(
      'POST',
      '/participants',
      status: 201,
      body: {'id': _profileId(6), 'first_name': 'Late', 'last_name': 'Joiner'},
    );
    await api.expectOk(
      'POST',
      '/contests/$_contestId/participations',
      status: 201,
      body: {
        'id': _participationId(6),
        'participant_profile_id': _profileId(6),
        'role_id': core.SystemRoles.pilotId.value,
      },
    );
    rounds = (matrix['rounds']! as List).cast<Map<String, Object?>>();
    assignments = (matrix['assignments']! as List).cast<Map<String, Object?>>();
  });
  tearDown(() => api.close());

  Future<(int, Map<String, Object?>)> call(String path, {String? token}) async {
    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/api/v1/self-scoring$path'),
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

  /// A guest session for pilot [n], through the link.
  Future<String> sessionFor(int n) async {
    final issued = await service.issue(
      contestId: core.Id.parse(_contestId),
      participationId: core.Id.parse(_participationId(n)),
      issuedBy: api.director,
      clientMutationId: 'issue-$n',
    );
    return (await service.resolve(issued.credential)).sessionToken;
  }

  Map<String, Object?> assignmentOf(int pilot, int round) =>
      assignments.singleWhere(
        (a) =>
            a['scheduled_round_id'] == rounds[round - 1]['id'] &&
            a['contest_participation_id'] == _participationId(pilot),
      );

  Future<void> directorScores(int pilot, int round, String mutation) =>
      api.expectOk(
        'POST',
        '/contests/$_contestId/assignments/${assignmentOf(pilot, round)['id']}'
            '/scores',
        status: 201,
        body: {
          'client_mutation_id': mutation,
          'base_score_revision': 0,
          'components': {
            'time_flown': 550,
            'launch_height': 100,
            'landing': 'points_50',
          },
        },
      );

  Future<void> openScoring() async => api.expectOk(
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

  test('the overview lists the pilot\'s own rounds and the next one', () async {
    final token = await sessionFor(1);
    final (status, body) = await call('/overview', token: token);
    expect(status, 200, reason: '$body');

    expect(
      (body['participant']! as Map)['participation_id'],
      _participationId(1),
    );
    expect((body['contest']! as Map)['round_count'], 3);
    expect(body['matrix_revision'], 1);
    expect((body['access']! as Map)['code'], 'scoring_closed');

    final list = (body['rounds']! as List).cast<Map<String, Object?>>();
    expect(list.map((r) => r['round']), [1, 2, 3]);
    for (final round in list) {
      expect(
        round['assignment_id'],
        assignmentOf(1, round['round']! as int)['id'],
      );
      expect(round['group'], matches(RegExp('^[AB]\$')));
      expect(round['state'], 'not_entered');
      expect(round['score_revision'], 0);
    }
    expect(list.map((r) => r['is_next_to_score']), [true, false, false]);

    // Nothing about another pilot reaches this one.
    expect(jsonEncode(body), isNot(contains('Blake')));
    expect(jsonEncode(body), isNot(contains(_participationId(2))));
  });

  test(
    'the next target follows the scored rounds; reopening is stable',
    () async {
      final token = await sessionFor(1);
      await openScoring();
      await directorScores(1, 1, 'entry-1');

      final (_, first) = await call('/overview', token: token);
      final (_, again) = await call('/overview', token: await sessionFor(1));
      final list = (first['rounds']! as List).cast<Map<String, Object?>>();
      expect(list.map((r) => r['state']), [
        'official',
        'not_entered',
        'not_entered',
      ]);
      expect(list.map((r) => r['is_next_to_score']), [false, true, false]);
      expect(list.first['entered_by'], 'Director');
      expect(list.first['entered_at'], isNotNull);
      expect(list.first['score_revision'], 1);
      expect((first['access']! as Map)['code'], 'open');
      // Reopening the link (a new session for the same invitation) reads the
      // same overview.
      expect(again, first);
      // Another pilot's scoring does not change this pilot's overview.
      await directorScores(2, 1, 'entry-2');
      final (_, afterOther) = await call('/overview', token: token);
      expect(afterOther, first);
    },
  );

  test('the entry context carries the form, landing table and rules', () async {
    final token = await sessionFor(1);
    final (status, body) = await call('/rounds/2/entry', token: token);
    expect(status, 200, reason: '$body');
    expect(body['assignment_id'], assignmentOf(1, 2)['id']);
    expect(body['round'], 2);
    expect(body['round_count'], 3);
    expect(body['matrix_revision'], 1);
    expect(body['score_revision'], 0);
    expect(body['state'], 'not_entered');
    expect(body['rules_version'], 'f5j-1');
    expect(body['allows_motor_restart'], isTrue);

    final keys = [
      for (final f in (body['fields']! as List).cast<Map<String, Object?>>())
        f['key'],
    ];
    expect(
      keys,
      containsAll(['time_flown', 'launch_height', 'landing', 'flight_penalty']),
    );
    expect(keys, isNot(contains('cumulative_penalty')));
    expect(keys, isNot(contains('raw_score')));
    final landing = (body['landing_table']! as List)
        .cast<Map<String, Object?>>();
    expect(landing.map((l) => l['id']), contains('points_50'));
    expect(landing.firstWhere((l) => l['id'] == 'points_50')['points'], 50);
  });

  test(
    'a motor restart field is left out when the contest forbids it',
    () async {
      await api.expectOk(
        'POST',
        '/contests/$_contestId/configuration',
        status: 201,
        body: {
          'base_revision_number': 1,
          'discipline_profile_id': core.SystemDisciplineProfiles.f5jId.value,
          'config': {
            'core': <String, Object?>{},
            'discipline': {
              'working_time': 600,
              'motor_restart_mode': 'not_allowed',
            },
          },
        },
      );
      final (_, body) = await call(
        '/rounds/1/entry',
        token: await sessionFor(1),
      );
      expect(body['allows_motor_restart'], isFalse);
      expect(
        (body['fields']! as List).map((f) => (f as Map)['key']),
        isNot(contains('motor_restart')),
      );
    },
  );

  test('a round the pilot has no flight in is a plain not_found', () async {
    final token = await sessionFor(1);
    for (final path in [
      '/rounds/0/entry',
      '/rounds/4/entry',
      '/rounds/x/entry',
    ]) {
      final (status, body) = await call(path, token: token);
      expect(status, 404, reason: path);
      expect((body['error']! as Map)['code'], 'not_found');
    }
  });

  test('no session, a made-up one, and a replaced link read nothing', () async {
    final token = await sessionFor(1);
    final stored = (await repository.invitationRepository.listForContest(
      core.Id.parse(_contestId),
    )).single;
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
    final answers = <String>{};
    for (final path in ['/overview', '/rounds/1/entry']) {
      for (final candidate in [null, 'not-a-session', token]) {
        final (status, body) = await call(path, token: candidate);
        expect(status, 401, reason: '$path $candidate');
        final error = Map<String, Object?>.of(
          (body['error']! as Map).cast<String, Object?>(),
        )..remove('requestId');
        answers.add(jsonEncode(error));
      }
    }
    expect(answers, hasLength(1));
    expect(answers.single, contains('session_invalid'));
  });

  test('the director\'s sign-in cannot read the participant routes', () async {
    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/api/v1/self-scoring/overview'),
        headers: {'authorization': 'Bearer director-token'},
      ),
    );
    expect(response.statusCode, 401);
  });

  /// Late pilot 6 flies in round 2 for the round they missed, round 1.
  Future<Map<String, Object?>> lateAddInRound2CreditedToRound1() async {
    final inRound2 = assignments
        .where((a) => a['scheduled_round_id'] == rounds[1]['id'])
        .toList();
    final counts = <Object?, int>{};
    for (final a in inRound2) {
      counts[a['group']] = (counts[a['group']] ?? 0) + 1;
    }
    final open = counts.entries.firstWhere((e) => e.value < 3).key;
    final body = await api.expectOk(
      'POST',
      '/contests/$_contestId/matrix/late-adds',
      status: 201,
      body: {
        'id': '019c0000-0000-7000-8000-000000000801',
        'contest_participation_id': _participationId(6),
        'scheduled_round_id': rounds[1]['id'],
        'credited_round_id': rounds[0]['id'],
        'group': open,
        'reason': 'Joined late',
      },
    );
    return (body['assignments']! as List)
        .cast<Map<String, Object?>>()
        .firstWhere(
          (a) => a['contest_participation_id'] == _participationId(6),
        );
  }

  test('a late add flown in round 2 is the pilot\'s round 1', () async {
    final added = await lateAddInRound2CreditedToRound1();
    final token = await sessionFor(6);
    final (_, body) = await call('/overview', token: token);
    final list = (body['rounds']! as List).cast<Map<String, Object?>>();
    expect(list, hasLength(1));
    expect(list.single['round'], 1);
    expect(list.single['assignment_id'], added['id']);
    expect(list.single['is_next_to_score'], isTrue);

    final (entryStatus, entry) = await call('/rounds/1/entry', token: token);
    expect(entryStatus, 200, reason: '$entry');
    expect(entry['assignment_id'], added['id']);
    // Round 2 is where it is flown, not what it counts for.
    expect((await call('/rounds/2/entry', token: token)).$1, 404);

    await openScoring();
    await api.expectOk(
      'POST',
      '/contests/$_contestId/assignments/${added['id']}/scores',
      status: 201,
      body: {
        'client_mutation_id': 'late-1',
        'base_score_revision': 0,
        'components': {
          'time_flown': 500,
          'launch_height': 100,
          'landing': 'points_50',
        },
      },
    );
    final (_, scored) = await call('/overview', token: token);
    final after = (scored['rounds']! as List).cast<Map<String, Object?>>();
    expect(after.single['state'], 'official');
    expect(after.single['is_next_to_score'], isFalse);
  });

  test('a pilot\'s own submission is attributed to their name', () async {
    final token = await sessionFor(1);
    final slot = assignmentOf(1, 1);
    final placeholder = (await repository.scorePlaceholderRepository
        .findForAssignment(core.Id.parse(slot['id']! as String)))!;
    final config = (await repository.contestConfigurationRevisionRepository
        .latestForContest(core.Id.parse(_contestId)))!;
    final matrix = (await repository.matrixRevisionRepository.latestForContest(
      core.Id.parse(_contestId),
    ))!;
    final now = DateTime.now().toUtc();
    final accepted = DateTime.utc(2026, 11, 6, 14, 30);
    final metadata = core.MutationMetadata(
      clientMutationId: 'p-1',
      authority: core.Authority.participant,
      clientTime: now,
      actorId: api.director,
    );
    await repository.scoreAttemptRepository.append(
      core.ScoreAttempt(
        id: core.Id.create(),
        contestId: core.Id.parse(_contestId),
        scorePlaceholderId: placeholder.id,
        configRevisionId: config.id,
        matrixRevisionId: matrix.id,
        rawComponents: const {'time_flown': 500, 'launch_height': 100},
        actorId: api.director,
        authority: core.Authority.participant,
        clientMutationId: 'p-1',
        baseScoreRevision: 0,
        acceptedAt: accepted,
      ),
      metadata: metadata,
    );
    await repository.scorePlaceholderRepository.save(
      core.ScorePlaceholder(
        id: placeholder.id,
        contestId: placeholder.contestId,
        contestParticipationId: placeholder.contestParticipationId,
        assignmentId: placeholder.assignmentId,
        state: core.ScorePlaceholderState.submitted,
        scoreRevision: 1,
        revision: placeholder.revision,
      ),
      metadata: core.MutationMetadata(
        clientMutationId: 'p-2',
        authority: core.Authority.participant,
        clientTime: now,
        actorId: api.director,
      ),
    );
    final (_, body) = await call('/overview', token: token);
    final first = (body['rounds']! as List).first as Map;
    expect(first['state'], 'submitted');
    expect(first['entered_by'], 'Pilot1 Rivera');
    // A preliminary score has no official score, so its time is the
    // attempt's server time.
    expect(DateTime.parse(first['entered_at']! as String), accepted);
    expect(first['is_next_to_score'], isFalse);
  });
}
