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
      expect(placeholder.state, core.ScorePlaceholderState.submitted);
      expect(placeholder.scoreRevision, 1);
      final attempts = await repository.scoreAttemptRepository
          .listForPlaceholder(placeholder.id);
      expect(attempts, hasLength(1));
      expect(attempts.single.authority, core.Authority.participant);
      expect(attempts.single.invitationId, isNotNull);
      expect(attempts.single.clientMutationId, 'm-1');
      expect(attempts.single.rawComponents, _goodScore);
      // Preliminary: no official score exists.
      expect(
        await repository.officialScoreRepository.currentForPlaceholder(
          placeholder.id,
        ),
        isNull,
      );
    },
  );

  test('a submission stays out of the official scores', () async {
    await submit(1);
    final scores = await api.expectOk('GET', '/contests/$_contestId/scores');
    final slots = (scores['scores']! as List).cast<Map<String, Object?>>();
    expect(slots.where((s) => s['official_score'] != null), isEmpty);
    expect(
      slots.where((s) => (s['placeholder']! as Map)['state'] == 'Submitted'),
      hasLength(1),
    );
  });

  test('the director can enter the official score over a submission', () async {
    final (_, first) = await submit(1);
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
        'base_score_revision': (first['score']! as Map)['revision'],
        'components': {..._goodScore, 'time_flown': 500},
        'reason': 'Checked the logger',
      },
    );
    final (status, body) = await submit(1, mutation: 'm-2');
    expect(status, 409);
    expect((body['accepted_score']! as Map)['state'], 'official');
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

  test('concurrent identical submissions store one and agree', () async {
    final results = await Future.wait([for (var i = 0; i < 4; i++) submit(1)]);
    expect(results.map((r) => r.$1).where((c) => c == 201), hasLength(1));
    expect(results.map((r) => r.$1).where((c) => c == 200), hasLength(3));
    final scores = {for (final r in results) jsonEncode(r.$2['score'])};
    expect(scores, hasLength(1));
    final attempts = await repository.scoreAttemptRepository.listForPlaceholder(
      (await placeholderOf(1, 1)).id,
    );
    expect(attempts, hasLength(1));
    expect(
      (results.first.$2['score']! as Map)['entered_at'],
      attempts.single.acceptedAt.toIso8601String(),
    );
  });

  test('concurrent submissions with different ids store one', () async {
    final results = await Future.wait([
      for (var i = 0; i < 3; i++) submit(1, mutation: 'm-$i'),
    ]);
    expect(results.map((r) => r.$1).where((c) => c == 201), hasLength(1));
    expect(results.map((r) => r.$1).where((c) => c == 409), hasLength(2));
    for (final r in results.where((r) => r.$1 == 409)) {
      expect(r.$2['code'], 'score_already_submitted');
    }
    final attempts = await repository.scoreAttemptRepository.listForPlaceholder(
      (await placeholderOf(1, 1)).id,
    );
    expect(attempts, hasLength(1));
  });

  test('a replay keeps next_round and survives a redraw', () async {
    final (_, first) = await submit(1);
    expect(first['next_round'], 2);
    await api.expectOk(
      'POST',
      '/contests/$_contestId/matrix/redraws',
      status: 201,
      body: {
        'id': '019c0000-0000-7000-8000-000000000503',
        'first_round': 2,
        'rounds': 2,
        'groups_per_round': 1,
        'random_seed': 11,
        'base_matrix_revision': matrixRevision,
      },
    );
    // The draw changed, so a new submission with the old revision is stale,
    // but the accepted one still replays, with the same score and next round.
    final (status, again) = await submit(1);
    expect(status, 200, reason: '$again');
    expect(again['score'], first['score']);
    expect(again['next_round'], 2);
    final (stale, staleBody) = await submit(2, mutation: 'm-2');
    expect(stale, 409);
    expect(staleBody['code'], 'stale_matrix');
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

  group('results (#146)', () {
    Future<(int, Map<String, Object?>)> get(String path) async {
      final response = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/api/v1/self-scoring$path'),
          headers: {'authorization': 'Bearer $token'},
        ),
      );
      final text = await response.readAsString();
      return (response.statusCode, jsonDecode(text) as Map<String, Object?>);
    }

    List<Map<String, Object?>> rowsOf(Map<String, Object?> body) =>
        (body['rows']! as List).cast<Map<String, Object?>>();

    test('the group shows a pilot score as preliminary', () async {
      expect((await submit(1)).$1, 201);
      final (status, body) = await get('/rounds/1/group-results');
      expect(status, 200, reason: '$body');
      expect(body['group'], 'A');
      expect(body['round'], 1);
      expect(body['latest_round'], 1);
      expect(body['preliminary'], isTrue);
      final rows = rowsOf(body);
      expect(rows, hasLength(3));
      final you = rows.first;
      expect(you['is_you'], isTrue);
      expect(you['pilot_name'], 'P1 X');
      expect(you['state'], 'submitted');
      expect(you['time_flown_seconds'], 540);
      expect(you['launch_height'], 45);
      expect(you['flight_score'], isA<num>());
      for (final other in rows.skip(1)) {
        expect(other['is_you'], isFalse);
        expect(other['state'], 'not_entered');
        expect(other['flight_score'], isNull);
        expect(other['time_flown_seconds'], isNull);
      }
    });

    test(
      'a pilot score never reaches the stored or director results',
      () async {
        await submit(1);
        final contest = core.Id.parse(_contestId);
        // Even a recalculation of the official results ignores the attempt.
        final official = await core.ResultsService(repository)
            .recalculate(contest);
        expect(official.standings, isEmpty);
        expect(
          await repository.participationStandingRepository.listForContest(
            contest,
          ),
          isEmpty,
        );
        expect(
          await repository.flightResultRepository.listForContest(contest),
          isEmpty,
        );
        expect(
          await repository.officialScoreRepository.currentForPlaceholder(
            (await placeholderOf(1, 1)).id,
          ),
          isNull,
        );
      },
    );

    test(
      'overall standings count the pilot score, labeled preliminary',
      () async {
        await submit(1);
        final (status, body) = await get('/results');
        expect(status, 200, reason: '$body');
        expect(body['as_of_round'], 1);
        expect(body['latest_round'], 1);
        expect(body['held_at_round'], isNull);
        expect(body['preliminary'], isTrue);
        expect(body['your_place'], 1);
        expect(body['your_score'], isA<num>());
        final standings = (body['standings']! as List)
            .cast<Map<String, Object?>>();
        expect(standings, hasLength(3));
        expect(standings.first['is_you'], isTrue);
        expect(standings.first['pilot_name'], 'P1 X');
      },
    );

    test('an official score replaces the attempt in the group', () async {
      await submit(1);
      final slot = assignments.singleWhere(
        (a) =>
            a['scheduled_round_id'] == rounds[0]['id'] &&
            a['contest_participation_id'] == _participationId(2),
      );
      await api.expectOk(
        'POST',
        '/contests/$_contestId/assignments/${slot['id']}/scores',
        status: 201,
        body: {
          'client_mutation_id': 'director-2',
          'base_score_revision': 0,
          'components': _goodScore,
          'reason': 'Entered by the director',
        },
      );
      final (_, body) = await get('/rounds/1/group-results');
      final byName = {for (final r in rowsOf(body)) r['pilot_name']: r};
      expect(byName['P1 X']!['state'], 'submitted');
      expect(byName['P2 X']!['state'], 'official');
      expect(byName['P2 X']!['flight_score'], isA<num>());
    });

    test('hiding results holds the overall standings, not the group', () async {
      expect((await submit(1)).$1, 201);
      expect((await submit(2, mutation: 'm-2')).$1, 201);
      final contestRepository = repository.contestRepository;
      final contest = (await contestRepository.findById(
        core.Id.parse(_contestId),
      ))!;
      await contestRepository.save(
        contest.copyWithState(
          hideResultsThroughRound: 1,
          updatedAt: DateTime.utc(2026, 10, 17, 16),
        ),
        metadata: core.MutationMetadata(
          clientMutationId: 'hide-1',
          authority: core.Authority.director,
          clientTime: DateTime.utc(2026, 10, 17, 16),
          actorId: api.director,
        ),
      );

      final (status, held) = await get('/results?round=2');
      expect(status, 200, reason: '$held');
      expect(held['as_of_round'], 1);
      expect(held['held_at_round'], 1);
      expect(held['latest_round'], 2);
      final (_, latest) = await get('/results');
      expect(latest['as_of_round'], 1);
      expect(latest['held_at_round'], 1);

      // Round scores and group positions stay current.
      final (groupStatus, group) = await get('/rounds/2/group-results');
      expect(groupStatus, 200, reason: '$group');
      expect(rowsOf(group).first['state'], 'submitted');
    });

    test('a round without scores or flights is not found', () async {
      await submit(1);
      expect((await get('/rounds/9/group-results')).$1, 404);
      expect((await get('/rounds/x/group-results')).$1, 404);
      expect((await get('/results?round=3')).$1, 404);
      expect((await get('/results?round=0')).$1, 404);
      expect((await get('/results?round=x')).$1, 404);
    });

    test(
      'a scored original with an unscored re-flight stays in its group',
      () async {
        await submit(1);
        final original = assignments.singleWhere(
          (a) =>
              a['scheduled_round_id'] == rounds[0]['id'] &&
              a['contest_participation_id'] == _participationId(1),
        );
        final source = (await repository.matrixAssignmentRepository.findById(
          core.Id.parse(original['id']! as String),
        ))!;
        final config = (await repository.contestConfigurationRevisionRepository
            .latestForContest(core.Id.parse(_contestId)))!;
        final now = DateTime.utc(2026, 10, 17, 16);
        final metadata = core.MutationMetadata(
          clientMutationId: 'rf-1',
          authority: core.Authority.director,
          clientTime: now,
          actorId: api.director,
        );
        final reFlight = await repository.reFlightRepository.save(
          core.ReFlight(
            id: core.Id.create(),
            contestId: source.contestId,
            creditedRoundId: source.scheduledRoundId,
            sourceRoundId: source.scheduledRoundId,
            sourceGroup: source.group,
            type: core.ReFlightType.moveToGroup,
            sequence: 1,
            status: core.ReFlightStatus.readyToFly,
            reason: 'Interference',
            scheduledRoundId: source.scheduledRoundId,
            flownGroup: 2,
            configRevisionId: config.id,
            createdBy: api.director,
            createdAt: now,
            groupFinalizedBy: api.director,
            groupFinalizedAt: now,
          ),
          metadata: metadata.forPart('rf'),
        );
        await repository.matrixAssignmentRepository.append(
          core.MatrixAssignment(
            id: core.Id.create(),
            contestId: source.contestId,
            matrixRevisionId: source.matrixRevisionId,
            contestParticipationId: source.contestParticipationId,
            scheduledRoundId: source.scheduledRoundId,
            creditedRoundId: source.creditedRoundId,
            group: 2,
            flightSequence: 2,
            assignmentType: core.AssignmentType.reflight,
            sourceAssignmentId: source.id,
            reFlightId: reFlight.id,
            actorId: api.director,
            reason: 'Interference',
            createdAt: now,
          ),
          metadata: metadata.forPart('rfa'),
        );

        final (status, body) = await get('/rounds/1/group-results');
        expect(status, 200, reason: '$body');
        expect(body['group'], 'A');
        final byName = {for (final r in rowsOf(body)) r['pilot_name']: r};
        expect(byName, hasLength(3));
        expect(byName['P1 X']!['state'], 'submitted');
        expect(byName['P1 X']!['time_flown_seconds'], 540);
      },
    );

    test(
      'a hidden-through round beyond the scored rounds is clamped',
      () async {
        await submit(1);
        final contestRepository = repository.contestRepository;
        final contest = (await contestRepository.findById(
          core.Id.parse(_contestId),
        ))!;
        await contestRepository.save(
          contest.copyWithState(
            hideResultsThroughRound: 3,
            updatedAt: DateTime.utc(2026, 10, 17, 16),
          ),
          metadata: core.MutationMetadata(
            clientMutationId: 'hide-3',
            authority: core.Authority.director,
            clientTime: DateTime.utc(2026, 10, 17, 16),
            actorId: api.director,
          ),
        );
        final (_, body) = await get('/results');
        expect(body['as_of_round'], 1);
        expect(body['held_at_round'], 1);
      },
    );

    test('a repeated round parameter is not found', () async {
      await submit(1);
      expect((await get('/results?round=1&round=1')).$1, 404);
      expect((await get('/results?round=1')).$1, 200);
    });

    test('results need the guest session', () async {
      final response = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/api/v1/self-scoring/results'),
        ),
      );
      expect(response.statusCode, 401);
    });
  });
}
