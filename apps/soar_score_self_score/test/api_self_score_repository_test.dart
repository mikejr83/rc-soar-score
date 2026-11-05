import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_self_score/data/api_self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_repository.dart';
import 'package:soar_score_self_score/models/group_result_row.dart';
import 'package:soar_score_self_score/models/pilot_round.dart';
import 'package:soar_score_self_score/models/score_submission.dart';
import 'package:soar_score_self_score/services/score_format.dart';

String _fixture(String name) =>
    File('../../packages/soar_score_api/fixtures/self_scoring/$name.json')
        .readAsStringSync();

http.Response _json(String body, [int status = 200]) => http.Response(
  body,
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

ApiSelfScoreRepository _repository(
  http.Response Function(http.Request request) respond,
) => ApiSelfScoreRepository(
  ApiClient(
    baseUrl: Uri.parse('http://localhost:8080'),
    httpClient: MockClient((request) async => respond(request)),
    tokenProvider: () async => 'session-1',
  ),
);

http.Response _fixtures(http.Request request) => switch (request.url.path) {
  '/api/v1/self-scoring/overview' => _json(_fixture('participant_overview')),
  '/api/v1/self-scoring/rounds/2/entry' => _json(_fixture('entry_context')),
  '/api/v1/self-scoring/rounds/1/group-results' => _json(
    _fixture('group_results'),
  ),
  '/api/v1/self-scoring/results' => _json(_fixture('overall_results')),
  '/api/v1/self-scoring/invitations/resolve' => _json(
    _fixture('resolve_invitation_response'),
  ),
  _ => _json('{}', 404),
};

const _submission = ScoreSubmission(
  contestId: 'c',
  pilotId: 'p',
  round: 2,
  matrixRevision: 3,
  clientMutationId: 'entry-7-2-1',
  components: {'time_flown': 540},
);

void main() {
  group('submitScore', () {
    test('an accepted score carries the server value and next round', () async {
      final result = await _repository(
        (_) => _json(_fixture('submit_response')),
      ).submitScore(_submission);
      expect(result, isA<ScoreAccepted>());
      result as ScoreAccepted;
      expect(result.flightScore, '962.5');
      expect(result.nextRound, 3);
    });

    test('score_already_submitted keeps the stored value', () async {
      final result = await _repository(
        (_) => _json(_fixture('error_score_already_submitted'), 409),
      ).submitScore(_submission);
      expect(result, isA<ScoreAlreadySubmitted>());
      expect((result as ScoreAlreadySubmitted).flightScore, '962.5');
    });

    test('a refusal names the fields at fault', () async {
      final result = await _repository(
        (_) => _json(_fixture('error_validation_failed'), 422),
      ).submitScore(_submission);
      expect(result, isA<ScoreRejected>());
      result as ScoreRejected;
      expect(result.code, 'validation_failed');
      expect(result.fields, ['time_flown', 'landing']);
    });

    test('a server fault is retryable, not a refusal', () {
      expect(
        _repository((_) => _json('<html>', 503)).submitScore(_submission),
        throwsA(isA<SelfScoreOfflineException>()),
      );
    });

    test('a dead connection is retryable', () {
      final repository = ApiSelfScoreRepository(
        ApiClient(
          baseUrl: Uri.parse('http://localhost:8080'),
          httpClient: MockClient((_) async => throw http.ClientException('x')),
        ),
      );
      expect(
        repository.submitScore(_submission),
        throwsA(isA<SelfScoreOfflineException>()),
      );
    });
  });

  test('accepting a link gives a guest session', () async {
    final session = await _repository(_fixtures).acceptInvitation('abc');
    expect(session.pilotName, 'Alex Rivera');
    expect(session.contestName, 'Summer Heater 2026');
    expect(session.token, 'example-session-token');
    expect(session.pilotId, '0192f6a0-0000-7000-8000-000000000002');
    expect(session.role, 'pilot');
    expect(session.expiresAt, DateTime.utc(2026, 11, 8, 23));
  });

  test('a cookie session keeps no token in the stored session', () async {
    final session = await _repository(
      (_) => _json(_fixture('resolve_invitation_response_cookie')),
    ).acceptInvitation('abc');
    expect(session.token, isNull);
    expect(session.toJson().containsKey('token'), isFalse);
    expect(jsonEncode(session.toJson()), isNot(contains('session')));
  });

  test('an invalid link is the one invalid-link failure', () async {
    final repository = _repository(
      (_) => _json(_fixture('error_invalid_invitation'), 404),
    );
    expect(
      repository.acceptInvitation('nope'),
      throwsA(isA<InvalidInvitationException>()),
    );
  });

  test('every kind of bad link reads the same, whatever the server says', () {
    for (final status in [400, 404, 410]) {
      final repository = _repository(
        (_) => _json(_fixture('error_invalid_invitation'), status),
      );
      expect(
        repository.acceptInvitation('x'),
        throwsA(isA<InvalidInvitationException>()),
      );
    }
  });

  test('a server fault while accepting is a load failure, not invalid', () {
    final repository = _repository((_) => _json('<html>', 502));
    expect(
      repository.acceptInvitation('abc'),
      throwsA(isA<SelfScoreLoadException>()),
    );
  });

  test('the pilot overview maps states to round statuses', () async {
    final overview = await _repository(_fixtures).pilotOverview('c', 'p');
    expect(overview.contestName, 'Summer Heater 2026');
    expect(overview.pilotNumber, 7);
    expect(overview.rounds.map((r) => r.status), [
      PilotRoundStatus.submitted,
      PilotRoundStatus.nextToScore,
      PilotRoundStatus.locked,
    ]);
    expect(overview.rounds.first.enteredBy, 'you');
    expect(overview.nextRound, 2);
  });

  test('the entry context carries the draw and the landing table', () async {
    final entry = await _repository(_fixtures).entryContext('c', 'p', 2);
    expect(entry.pilotName, 'Alex Rivera');
    expect(entry.group, 'B');
    expect(entry.lane, isNull);
    expect(entry.roundCount, 5);
    expect(entry.landingTable.map((l) => l.label), ['Good', 'Fair', 'Off']);
  });

  test('group results show zero, estimate and own rows', () async {
    final group = await _repository(_fixtures).groupResults('c', 'p', 1);
    expect(group.group, 'A');
    expect(group.latestRound, 2);
    final you = group.rows[0];
    expect(you.isYou, isTrue);
    expect(you.time, '9:00');
    expect(you.score, '962.5');
    expect(you.detail, 'Height 45 m · Good 50');
    final zero = group.rows[1];
    expect(zero.kind, GroupRowKind.zero);
    expect(zero.zeroReason, 'landed out');
    final pending = group.rows[2];
    expect(pending.kind, GroupRowKind.noScore);
    expect(pending.score, isNull);
    expect(pending.detail, 'Estimate 900');
  });

  test('overall results keep the held round and have no teams', () async {
    final results = await _repository(_fixtures).results('c');
    expect(results.heldRound, 1);
    expect(results.latestRound, 2);
    expect(results.snapshot.round, 1);
    expect(results.snapshot.ordinal, '2nd');
    expect(results.snapshot.score, '962.5');
    expect(results.snapshot.pilots.map((p) => p.place), ['1', '2', '3']);
    expect(results.snapshot.pilots[1].isYou, isTrue);
    expect(results.snapshot.teams, isEmpty);
  });

  test('a lost session asks for the link again', () async {
    final repository = _repository(
      (_) => _json(
        jsonEncode({
          'code': 'session_invalid',
          'message': 'x',
          'field_errors': <Object>[],
        }),
        401,
      ),
    );
    expect(
      repository.pilotOverview('c', 'p'),
      throwsA(
        isA<SelfScoreLoadException>().having(
          (e) => e.message,
          'message',
          contains('invitation link'),
        ),
      ),
    );
    expect(
      repository.pilotOverview('c', 'p'),
      throwsA(isA<SessionEndedException>()),
    );
  });

  test('score and ordinal formatting', () {
    expect(ScoreFormat.score(2184), '2,184');
    expect(ScoreFormat.score(962.5), '962.5');
    expect(ScoreFormat.score(900.0), '900');
    expect(ScoreFormat.score(1234567.25), '1,234,567.3');
    expect([1, 2, 3, 4, 11, 12, 13, 21, 22, 103].map(ScoreFormat.ordinal), [
      '1st',
      '2nd',
      '3rd',
      '4th',
      '11th',
      '12th',
      '13th',
      '21st',
      '22nd',
      '103rd',
    ]);
  });
}
