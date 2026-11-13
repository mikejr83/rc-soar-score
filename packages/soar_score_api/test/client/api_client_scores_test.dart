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
  final assignmentId = Id.parse('019c0000-0000-7000-8000-000000000060');
  final placeholderId = Id.parse('019c0000-0000-7000-8000-000000000061');
  final participationId = Id.parse('019c0000-0000-7000-8000-000000000062');
  final actor = Id.parse('019c0000-0000-7000-8000-000000000050');
  final contest = Contest(
    id: contestId,
    name: 'Spring Open',
    startDateTime: DateTime.utc(2026, 10, 17, 14),
    endDateTime: DateTime.utc(2026, 10, 18, 22),
    timezone: 'America/Denver',
    createdAt: DateTime.utc(2026, 9),
    updatedAt: DateTime.utc(2026, 9),
  );
  final placeholder = ScorePlaceholder(
    id: placeholderId,
    contestId: contestId,
    contestParticipationId: participationId,
    assignmentId: assignmentId,
    state: ScorePlaceholderState.official,
    scoreRevision: 1,
  );
  final official = OfficialScore(
    id: Id.parse('019c0000-0000-7000-8000-000000000063'),
    contestId: contestId,
    scorePlaceholderId: placeholderId,
    scoreAttemptId: Id.parse('019c0000-0000-7000-8000-000000000064'),
    scoreRevision: 1,
    components: const {'time_flown': 540, 'launch_height': 200},
    setAt: DateTime.utc(2026, 10, 17, 15),
    setBy: actor,
    reason: 'Entered by the director',
  );
  const calculated = CalculatedFlight(
    outcome: FlightOutcome.scored,
    rawScore: 440,
    flightPoints: 540,
    heightPenalty: 100,
  );

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

  test('scores(id) GETs the slots and round progress', () async {
    final scores = ContestScores(
      slots: [ScoreSlot(placeholder: placeholder, officialScore: official)],
      rounds: [
        RoundProgress(
          roundId: Id.parse('019c0000-0000-7000-8000-000000000065'),
          ordinal: 1,
          scored: 1,
          total: 4,
        ),
      ],
    );
    final client = clientFor((_) => body(scores.toJson()));

    expect(await client.scores(contestId), scores);
    expect(seen.method, 'GET');
    expect(seen.url.path, '/api/v1/contests/${contestId.value}/scores');
  });

  test('enterScore POSTs the request and decodes the entry', () async {
    final result = ScoreEntryResult(
      officialScore: official,
      placeholder: placeholder,
      contest: contest,
      calculated: calculated,
    );
    final client = clientFor((_) => body(result.toJson(), 201));
    const request = EnterScoreRequest(
      clientMutationId: 'entry-1',
      baseScoreRevision: 0,
      components: {'time_flown': 540, 'launch_height': 200},
    );

    expect(await client.enterScore(contestId, assignmentId, request), result);
    expect(seen.method, 'POST');
    expect(
      seen.url.path,
      '/api/v1/contests/${contestId.value}/assignments/${assignmentId.value}'
      '/scores',
    );
    expect(jsonDecode(seen.body), request.toJson());
  });

  test('promoteScore POSTs the source and decodes the entry', () async {
    final result = ScorePromotionResult(
      entry: ScoreEntryResult(
        officialScore: official,
        placeholder: placeholder,
        contest: contest,
        calculated: calculated,
      ),
      replayed: true,
    );
    final client = clientFor((_) => body(result.toJson(), 200));
    const request = PromoteScoreRequest(
      sourceAttemptId: '019c0000-0000-7000-8000-000000000077',
      expectedScoreRevision: 1,
    );

    final promoted = await client.promoteScore(
      contestId,
      assignmentId,
      request,
    );

    expect(promoted.replayed, isTrue);
    expect(promoted.entry, result.entry);
    expect(seen.method, 'POST');
    expect(
      seen.url.path,
      '/api/v1/contests/${contestId.value}/assignments/${assignmentId.value}'
      '/scores/official',
    );
    expect(jsonDecode(seen.body), request.toJson());
  });

  test('promoteGroup POSTs the items and decodes the outcomes', () async {
    final result = GroupPromotionResult(
      outcomes: [
        PromotionOutcome.adopted(
          assignmentId,
          ScorePromotionResult(
            entry: ScoreEntryResult(
              officialScore: official,
              placeholder: placeholder,
              contest: contest,
              calculated: calculated,
            ),
            replayed: false,
          ),
        ),
        PromotionOutcome.refused(
          Id.parse('019c0000-0000-7000-8000-000000000099'),
          statusCode: 409,
          code: 'stale_revision',
          message: 'stale',
        ),
      ],
      notRequested: [Id.parse('019c0000-0000-7000-8000-000000000098')],
    );
    final client = clientFor((_) => body(result.toJson(), 200));
    final request = PromoteGroupRequest(
      items: [
        PromoteGroupItem(
          assignmentId: assignmentId.value,
          sourceAttemptId: '019c0000-0000-7000-8000-000000000077',
          expectedScoreRevision: 1,
        ),
      ],
    );

    final answer = await client.promoteGroup(
      contestId,
      Id.parse('019c0000-0000-7000-8000-000000000050'),
      2,
      request,
    );

    expect(answer, result);
    expect(
      seen.url.path,
      '/api/v1/contests/${contestId.value}/rounds/'
      '019c0000-0000-7000-8000-000000000050/groups/2/scores/official',
    );
    expect(jsonDecode(seen.body), request.toJson());
  });

  test('scoreHistory(id, assignmentId) GETs the slot history', () async {
    final history = ScoreHistory(
      assignmentId: assignmentId,
      entries: [
        ScoreHistoryEntry(
          attemptId: official.scoreAttemptId,
          outcome: ScoreHistoryOutcome.current,
          scoreRevision: 1,
          components: official.components,
          reason: official.reason,
          actorId: actor,
          authority: Authority.director,
          at: official.setAt,
        ),
        ScoreHistoryEntry(
          attemptId: Id.parse('019c0000-0000-7000-8000-000000000066'),
          outcome: ScoreHistoryOutcome.notAdopted,
          components: const {'time_flown': 600},
          actorId: actor,
          authority: Authority.participant,
        ),
      ],
    );
    final client = clientFor((_) => body(history.toJson()));

    expect(await client.scoreHistory(contestId, assignmentId), history);
    expect(seen.method, 'GET');
    expect(
      seen.url.path,
      '/api/v1/contests/${contestId.value}/assignments/${assignmentId.value}'
      '/scores/history',
    );
  });

  test('a stale score is a 409 with its code', () async {
    final client = clientFor(
      (_) => body({
        'error': {
          'code': 'stale_revision',
          'message': 'stale',
          'requestId': 'r1',
        },
      }, 409),
    );

    await expectLater(
      client.enterScore(
        contestId,
        assignmentId,
        const EnterScoreRequest(
          clientMutationId: 'entry-2',
          baseScoreRevision: 0,
          components: {'motor_restart': true},
        ),
      ),
      throwsA(
        isA<ApiHttpError>()
            .having((e) => e.statusCode, 'status', 409)
            .having((e) => e.error?.code, 'code', 'stale_revision'),
      ),
    );
  });

  test('enterScores posts every entry once and decodes each outcome', () async {
    final result = ScoreEntryResult(
      officialScore: official,
      placeholder: placeholder,
      contest: contest,
      calculated: calculated,
    );
    final client = clientFor(
      (_) => body({
        'results': [
          {'result': result.toJson()},
          {
            'error': {
              'status': 409,
              'code': 'stale_revision',
              'message': 'stale',
            },
          },
        ],
        'recalculation_warning': 'results are stale',
      }),
    );

    final answer = await client.enterScores(
      contestId,
      EnterScoresRequest(
        entries: [
          EnterScoresEntry(
            assignmentId: assignmentId,
            clientMutationId: 'bulk-1',
            baseScoreRevision: 0,
            components: const {'time_flown': 540},
          ),
          EnterScoresEntry(
            assignmentId: placeholderId,
            clientMutationId: 'bulk-2',
            baseScoreRevision: 1,
            components: const {'time_flown': 500},
            reason: 'fixed',
          ),
        ],
      ),
    );

    expect(seen.method, 'POST');
    expect(seen.url.path, '/api/v1/contests/${contestId.value}/scores/bulk');
    final sent = jsonDecode(seen.body) as Map<String, Object?>;
    final entries = (sent['entries']! as List).cast<Map>();
    expect(entries, hasLength(2));
    expect(entries[0]['assignment_id'], assignmentId.value);
    expect(entries[1]['reason'], 'fixed');
    expect(answer.results[0].isSaved, isTrue);
    expect(answer.results[0].result, result);
    expect(answer.results[1].isSaved, isFalse);
    expect(answer.results[1].statusCode, 409);
    expect(answer.results[1].code, 'stale_revision');
    expect(answer.recalculationWarning, 'results are stale');
  });
}
