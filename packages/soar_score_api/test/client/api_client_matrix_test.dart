import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  final baseUrl = Uri.parse('http://localhost:8085');
  const jsonHeaders = <String, String>{
    'content-type': 'application/json; charset=utf-8',
  };
  final contestId = Id.parse('019c0000-0000-7000-8000-000000000020');
  final revisionId = Id.parse('019c0000-0000-7000-8000-000000000501');
  final matrixPath = '/api/v1/contests/${contestId.value}/matrix';

  late http.Request seen;

  ApiClient clientFor(http.Response Function(http.Request) respond) {
    final client = ApiClient(
      baseUrl: baseUrl,
      httpClient: MockClient((request) async {
        seen = request;
        return respond(request);
      }),
    );
    addTearDown(client.close);
    return client;
  }

  http.Response body(Object json, [int status = 200]) =>
      http.Response(jsonEncode(json), status, headers: jsonHeaders);

  test('matrix(id) reads the current matrix, empty before a draw', () async {
    final client = clientFor((_) => body(CurrentMatrix().toJson()));

    final matrix = await client.matrix(contestId);

    expect(matrix.isEmpty, isTrue);
    expect(seen.method, 'GET');
    expect(seen.url.path, matrixPath);
  });

  test('drawMatrix POSTs the request and decodes the matrix', () async {
    final client = clientFor((_) => body(CurrentMatrix().toJson(), 201));
    final request = DrawMatrixRequest(
      id: revisionId,
      rounds: 5,
      groupsPerRound: 3,
      randomSeed: 42,
      attemptsPerRound: 20,
      seedCount: 4,
    );

    await client.drawMatrix(contestId, request);

    expect(seen.method, 'POST');
    expect(seen.url.path, '$matrixPath/draws');
    expect(jsonDecode(seen.body), {
      'id': revisionId.value,
      'rounds': 5,
      'groups_per_round': 3,
      'random_seed': 42,
      'attempts_per_round': 20,
      'seed_count': 4,
    });
  });

  Map<String, Object?> running() => {
    'id': revisionId.value,
    'state': 'running',
    'percent': 40,
    'seed': 2,
    'seed_count': 3,
  };

  test('drawStatus GETs how far a draw has come', () async {
    final client = clientFor((_) => body(running()));

    final status = await client.drawStatus(contestId, revisionId);

    expect(seen.method, 'GET');
    expect(seen.url.path, '$matrixPath/draws/${revisionId.value}');
    expect(status!.running, isTrue);
    expect(status.percent, 40);
    expect(status.seed, 2);
    expect(status.seedCount, 3);
  });

  test('cancelDraw DELETEs the draw and returns its status', () async {
    final client = clientFor((_) => body({...running(), 'state': 'cancelled'}));

    final status = await client.cancelDraw(contestId, revisionId);

    expect(seen.method, 'DELETE');
    expect(seen.url.path, '$matrixPath/draws/${revisionId.value}');
    expect(status!.state, DrawJobState.cancelled);
  });

  test('a draw the server does not know is null', () async {
    final client = clientFor(
      (_) => body({
        'error': {'code': 'not_found', 'message': 'no such draw'},
      }, 404),
    );

    expect(await client.drawStatus(contestId, revisionId), isNull);
    expect(await client.cancelDraw(contestId, revisionId), isNull);
  });

  test('a conflict is an ApiHttpError', () async {
    final client = clientFor(
      (_) => body({
        'error': {'code': 'matrix_exists', 'message': 'already drawn'},
      }, 409),
    );

    await expectLater(
      client.drawMatrix(
        contestId,
        DrawMatrixRequest(id: revisionId, rounds: 1, groupsPerRound: 1),
      ),
      throwsA(isA<ApiHttpError>().having((e) => e.statusCode, 'status', 409)),
    );
  });

  test('matrixRevisions GETs the list and decodes the summaries', () async {
    final client = clientFor((_) => body({
      'revisions': [
        {
          'id': revisionId.value,
          'revision_number': 1,
          'created_at': '2026-10-17T14:00:00.000Z',
          'reason': 'initial draw',
          'created_by': contestId.value,
          'first_round': 1,
          'last_round': 3,
          'algorithm_version': '1.0.0',
          'random_seed': 7,
          'fairness_score': 0.15,
        },
      ],
    }));

    final revisions = await client.matrixRevisions(contestId);

    expect(seen.method, 'GET');
    expect(seen.url.path, '$matrixPath/revisions');
    expect(revisions, hasLength(1));
    expect(revisions.first.id, revisionId);
    expect(revisions.first.revisionNumber, 1);
    expect(revisions.first.reason, 'initial draw');
    expect(revisions.first.createdBy, contestId);
    expect(revisions.first.firstRound, 1);
    expect(revisions.first.lastRound, 3);
    expect(revisions.first.algorithmVersion, '1.0.0');
    expect(revisions.first.randomSeed, 7);
    expect(revisions.first.fairnessScore, 0.15);
    expect(
      revisions.first.createdAt,
      DateTime.utc(2026, 10, 17, 14),
    );
  });

  test('matrixRevisions is an empty list before a draw', () async {
    final client = clientFor((_) => body({'revisions': <Object?>[]}));

    expect(await client.matrixRevisions(contestId), isEmpty);
  });

  test('matrixRevision GETs one revision and decodes its matrix', () async {
    final client = clientFor((_) => body(CurrentMatrix().toJson()));

    final matrix = await client.matrixRevision(contestId, revisionId);

    expect(seen.method, 'GET');
    expect(
      seen.url.path,
      '$matrixPath/revisions/${revisionId.value}',
    );
    expect(matrix.isEmpty, isTrue);
  });

  test('a revision the server does not know is an ApiHttpError 404', () async {
    final client = clientFor(
      (_) => body({
        'error': {
          'code': 'not_found',
          'message': 'no such matrix revision',
        },
      }, 404),
    );

    await expectLater(
      client.matrixRevision(contestId, revisionId),
      throwsA(isA<ApiHttpError>().having((e) => e.statusCode, 'status', 404)),
    );
  });

  test('moveAssignment POSTs the move and decodes the matrix', () async {
    final client = clientFor((_) => body(CurrentMatrix().toJson(), 201));
    final assignmentId = Id.parse('019c0000-0000-7000-8000-000000000601');
    final newId = Id.parse('019c0000-0000-7000-8000-000000000602');

    await client.moveAssignment(
      contestId,
      assignmentId,
      MoveAssignmentRequest(
        id: newId,
        group: 2,
        lane: 3,
        reason: 'Wrong group',
        overrideLocks: true,
      ),
    );

    expect(seen.method, 'POST');
    expect(
      seen.url.path,
      '$matrixPath/assignments/${assignmentId.value}/moves',
    );
    expect(jsonDecode(seen.body), {
      'id': newId.value,
      'scheduled_round_id': null,
      'group': 2,
      'lane': 3,
      'reason': 'Wrong group',
      'override_locks': true,
    });
  });

  test('lateAdd POSTs the request and decodes the matrix', () async {
    final client = clientFor((_) => body(CurrentMatrix().toJson(), 201));
    final newId = Id.parse('019c0000-0000-7000-8000-000000000602');
    final pilot = Id.parse('019c0000-0000-7000-8000-000000000206');
    final round = Id.parse('019c0000-0000-7000-8000-000000000081');

    await client.lateAdd(
      contestId,
      LateAddRequest(
        id: newId,
        contestParticipationId: pilot,
        scheduledRoundId: round,
        group: 2,
        reason: 'Joined late',
      ),
    );

    expect(seen.method, 'POST');
    expect(seen.url.path, '$matrixPath/late-adds');
    expect(jsonDecode(seen.body), {
      'id': newId.value,
      'contest_participation_id': pilot.value,
      'scheduled_round_id': round.value,
      'credited_round_id': null,
      'group': 2,
      'lane': null,
      'reason': 'Joined late',
    });
  });

  test('placeInAllRounds POSTs the pilot and decodes each round', () async {
    final pilot = Id.parse('019c0000-0000-7000-8000-000000000206');
    final client = clientFor(
      (_) => body({
        'rounds': [
          {'round': 1, 'group': 2, 'lane': null, 'zeroed': true},
          {'round': 2, 'skipped_reason': 'group 2 has no open spot'},
        ],
        'recalculation_warning': null,
      }, 201),
    );

    final result = await client.placeInAllRounds(contestId, pilot);

    expect(seen.method, 'POST');
    expect(seen.url.path, '$matrixPath/late-placements');
    expect(jsonDecode(seen.body), {'contest_participation_id': pilot.value});
    expect(result.placed.single.round, 1);
    expect(result.zeroed.single.round, 1);
    expect(result.skipped.single.skippedReason, 'group 2 has no open spot');
  });

  test('redrawMatrix POSTs the request and decodes the matrix', () async {
    final client = clientFor((_) => body(CurrentMatrix().toJson(), 201));
    final newId = Id.parse('019c0000-0000-7000-8000-000000000603');

    await client.redrawMatrix(
      contestId,
      RedrawMatrixRequest(
        id: newId,
        firstRound: 4,
        rounds: 2,
        groupsPerRound: 3,
        randomSeed: 5,
        reason: 'Two more rounds',
      ),
    );

    expect(seen.method, 'POST');
    expect(seen.url.path, '$matrixPath/redraws');
    expect(jsonDecode(seen.body), {
      'id': newId.value,
      'first_round': 4,
      'rounds': 2,
      'groups_per_round': 3,
      'random_seed': 5,
      'attempts_per_round': null,
      'seed_count': null,
      'reason': 'Two more rounds',
    });
  });
}
