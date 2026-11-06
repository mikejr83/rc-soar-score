import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;
import 'package:soar_score_data/soar_score_data.dart';
import 'package:soar_score_server/handler.dart';
import 'package:test/test.dart';

import 'slice_client.dart';

const _contestId = '019c0000-0000-7000-8000-000000000030';
const _secret = 'a-test-secret-that-is-at-least-32-bytes-long';

String _profileId(int n) => '019c0000-0000-7000-8000-00000000a1${_two(n)}';
String _participationId(int n) =>
    '019c0000-0000-7000-8000-00000000b2${_two(n)}';
String _two(int n) => n.toString().padLeft(2, '0');

const _goodScore = {
  'time_flown': 540,
  'launch_height': 45,
  'landing': 'points_50',
};

/// A pilot's own score submission over a real database, the way the
/// self-scoring app calls it: JSON over `/self-scoring/rounds/{n}/scores`
/// with the guest session of an invitation link.
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
  late String token;
  late int matrixRevision;
  late List<Map<String, Object?>> rounds;
  late List<Map<String, Object?>> assignments;

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
    for (var n = 1; n <= 3; n++) {
      await api.expectOk(
        'POST',
        '/participants',
        status: 201,
        body: {'id': _profileId(n), 'first_name': 'P$n', 'last_name': 'X'},
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
        'id': '019c0000-0000-7000-8000-000000000502',
        'rounds': 3,
        'groups_per_round': 1,
        'random_seed': 7,
      },
    );
    rounds = (matrix['rounds']! as List).cast<Map<String, Object?>>();
    assignments = (matrix['assignments']! as List).cast<Map<String, Object?>>();
    matrixRevision =
        (await repository.matrixRevisionRepository.latestForContest(
          core.Id.parse(_contestId),
        ))!.revisionNumber;
    await contestAction('openScoring');
    final issued = await service.issue(
      contestId: core.Id.parse(_contestId),
      participationId: core.Id.parse(_participationId(1)),
      issuedBy: api.director,
      clientMutationId: 'issue-1',
    );
    token = (await service.resolve(issued.credential)).sessionToken;
  });
  tearDown(() => api.close());

  Future<(int, Map<String, Object?>)> submit(
    int round, {
    String mutation = 'm-1',
    Map<String, Object?> components = _goodScore,
    int? revision,
  }) async {
    final response = await handler(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/self-scoring/rounds/$round/scores'),
        body: jsonEncode({
          'client_mutation_id': mutation,
          'matrix_revision': revision ?? matrixRevision,
          'components': components,
        }),
        headers: {'authorization': 'Bearer $token'},
      ),
    );
    final text = await response.readAsString();
    return (response.statusCode, jsonDecode(text) as Map<String, Object?>);
  }

  Future<core.ScorePlaceholder> placeholderOf(int round, int pilot) async {
    final slot = assignments.singleWhere(
      (a) =>
          a['scheduled_round_id'] == rounds[round - 1]['id'] &&
          a['contest_participation_id'] == _participationId(pilot),
    );
    return (await repository.scorePlaceholderRepository.findForAssignment(
      core.Id.parse(slot['id']! as String),
    ))!;
  }

  Future<String> contestState() async =>
      (await api.expectOk('GET', '/contests/$_contestId'))['lifecycle_state']!
          as String;

  test(
    'the first accepted submission is stored and starts the contest',
    () async {
      expect(await contestState(), 'Ready');
      final (status, body) = await submit(1);
      expect(status, 201, reason: '$body');
      final score = body['score']! as Map;
      expect(score['state'], 'submitted');
      expect(score['round'], 1);
      expect(score['revision'], 1);
      expect(score['entered_by'], 'P1 X');
      expect(score['components'], _goodScore);
      expect(score['flight_score'], isA<num>());
      expect(body['next_operation'], 'view_results');
      expect(body['next_round'], 2);
      expect(await contestState(), 'Running');

      final placeholder = await placeholderOf(1, 1);
      expect(placeholder.state, core.ScorePlaceholderState.official);
      final attempts = await repository.scoreAttemptRepository
          .listForPlaceholder(placeholder.id);
      expect(attempts, hasLength(1));
      expect(attempts.single.authority, core.Authority.participant);
      expect(attempts.single.invitationId, isNotNull);
      expect(attempts.single.clientMutationId, 'm-1');
      final official = (await repository.officialScoreRepository
          .currentForPlaceholder(placeholder.id))!;
      expect(official.scoreAttemptId, attempts.single.id);
      expect(official.setBy, attempts.single.actorId);
    },
  );

  test('the results are recalculated after a submission', () async {
    await submit(1);
    final results = await api.expectOk('GET', '/contests/$_contestId/results');
    expect(results['as_of_round'], 1);
    expect((results['standings']! as List), isNotEmpty);
  });

  test('a repeat of the same request answers the first acceptance', () async {
    final (_, first) = await submit(1);
    final (status, again) = await submit(1);
    expect(status, 200, reason: '$again');
    expect(again['score'], first['score']);
    final attempts = await repository.scoreAttemptRepository.listForPlaceholder(
      (await placeholderOf(1, 1)).id,
    );
    expect(attempts, hasLength(1));
  });

  test('a request id reused with other data is a mutation_conflict', () async {
    await submit(1);
    final (status, body) = await submit(
      1,
      components: {..._goodScore, 'time_flown': 300},
    );
    expect(status, 409);
    expect(body['code'], 'mutation_conflict');
    final (otherRound, other) = await submit(2);
    expect(otherRound, 409);
    expect(other['code'], 'mutation_conflict');
  });

  test(
    'a second submission is score_already_submitted with the first',
    () async {
      final (_, first) = await submit(1);
      final (status, body) = await submit(
        1,
        mutation: 'm-2',
        components: {..._goodScore, 'time_flown': 300},
      );
      expect(status, 409);
      expect(body['code'], 'score_already_submitted');
      expect(body['accepted_score'], first['score']);
      expect(body['next_operation'], 'view_results');
      final attempts = await repository.scoreAttemptRepository
          .listForPlaceholder((await placeholderOf(1, 1)).id);
      expect(attempts, hasLength(1));
    },
  );

  test('a score the director entered first is not replaced', () async {
    final slot = assignments.singleWhere(
      (a) =>
          a['scheduled_round_id'] == rounds[0]['id'] &&
          a['contest_participation_id'] == _participationId(1),
    );
    await api.expectOk(
      'POST',
      '/contests/$_contestId/assignments/${slot['id']}/scores',
      status: 201,
      body: {
        'client_mutation_id': 'director-1',
        'base_score_revision': 0,
        'components': _goodScore,
      },
    );
    final (status, body) = await submit(1);
    expect(status, 409);
    expect(body['code'], 'score_already_submitted');
    expect((body['accepted_score']! as Map)['state'], 'official');
    expect((body['accepted_score']! as Map)['entered_by'], 'Director');
  });

  test('a cumulative penalty is rejected and nothing changes', () async {
    final (status, body) = await submit(
      1,
      components: {..._goodScore, 'cumulative_penalty': 0},
    );
    expect(status, 400);
    expect(body['code'], 'validation_failed');
    expect(body['field_errors'], [
      {'field': 'cumulative_penalty', 'code': 'not_allowed'},
    ]);
    expect(await contestState(), 'Ready');
    expect((await placeholderOf(1, 1)).scoreRevision, 0);
  });

  test('missing, wrong and out-of-range fields are named', () async {
    final (missing, missingBody) = await submit(
      1,
      components: {'launch_height': 45, 'landing': 'points_50'},
    );
    expect(missing, 400);
    expect(missingBody['field_errors'], [
      {'field': 'time_flown', 'code': 'required'},
    ]);

    final (wrong, wrongBody) = await submit(
      1,
      mutation: 'm-2',
      components: {..._goodScore, 'launch_height': 'high'},
    );
    expect(wrong, 400);
    expect(wrongBody['field_errors'], [
      {'field': 'launch_height', 'code': 'wrong_type'},
    ]);

    final (range, rangeBody) = await submit(
      1,
      mutation: 'm-3',
      components: {..._goodScore, 'time_flown': -5},
    );
    expect(range, 400);
    expect(rangeBody['field_errors'], [
      {'field': 'time_flown', 'code': 'out_of_range'},
    ]);

    final (unknown, unknownBody) = await submit(
      1,
      mutation: 'm-4',
      components: {..._goodScore, 'invented': 1},
    );
    expect(unknown, 400);
    expect(unknownBody['field_errors'], [
      {'field': 'invented', 'code': 'not_allowed'},
    ]);
    expect((await placeholderOf(1, 1)).scoreRevision, 0);
  });

  test('rounds are scored in order', () async {
    final (status, body) = await submit(2);
    expect(status, 409);
    expect(body['code'], 'out_of_order');
    expect((await placeholderOf(2, 1)).scoreRevision, 0);

    expect((await submit(1)).$1, 201);
    final (second, secondBody) = await submit(2, mutation: 'm-2');
    expect(second, 201, reason: '$secondBody');
    expect(secondBody['next_round'], 3);
  });

  test('a stale draw is stale_matrix', () async {
    final (status, body) = await submit(1, revision: matrixRevision + 1);
    expect(status, 409);
    expect(body['code'], 'stale_matrix');
    expect(await contestState(), 'Ready');
  });

  test('a round the pilot has no flight in is not found', () async {
    final (status, _) = await submit(9);
    expect(status, 404);
  });

  test('a closed or locked contest takes no submission', () async {
    await contestAction('closeScoring');
    final (closed, closedBody) = await submit(1);
    expect(closed, 409);
    expect((closedBody['error']! as Map)['code'], 'scoring_closed');
    expect((await placeholderOf(1, 1)).scoreRevision, 0);
  });
}
