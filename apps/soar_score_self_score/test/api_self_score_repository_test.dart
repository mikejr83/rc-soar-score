import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_self_score/data/api_self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_repository.dart';
import 'package:soar_score_self_score/models/entry_context.dart';
import 'package:soar_score_self_score/models/group_result_row.dart';
import 'package:soar_score_self_score/models/guest_session.dart';
import 'package:soar_score_self_score/models/pilot_overview.dart';
import 'package:soar_score_self_score/models/pilot_round.dart';
import 'package:soar_score_self_score/models/score_submission.dart';
import 'package:soar_score_self_score/services/score_format.dart';
import 'package:soar_score_self_score/session/guest_session_store.dart';

String _fixture(String name) =>
    File('../../packages/soar_score_api/fixtures/self_scoring/$name.json')
        .readAsStringSync();

http.Response _json(String body, [int status = 200]) => http.Response(
  body,
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

final _requested = <String>[];

ApiSelfScoreRepository _repository(
  http.Response Function(http.Request request) respond, {
  bool signedIn = true,
}) {
  final sessions = MemoryGuestSessionStore();
  if (signedIn) {
    sessions.write(
      GuestSession(
        contestId: 'c',
        contestName: 'Summer Heater 2026',
        pilotId: 'p',
        pilotName: 'Alex Rivera',
        pilotNumber: 7,
        token: 'session-1',
        expiresAt: DateTime.utc(2099),
      ),
    );
  }
  return ApiSelfScoreRepository(
    ApiClient(
      baseUrl: Uri.parse('http://localhost:8080'),
      httpClient: MockClient((request) async {
        _requested.add(request.url.path);
        return respond(request);
      }),
      tokenProvider: () async => 'session-1',
    ),
    sessions,
  );
}

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
  setUp(_requested.clear);

  group('submitScore', () {
    test('an accepted score carries the server value and next round', () async {
      final result = await _repository(
        (_) => _json(_fixture('submit_response')),
      ).submitScore(_submission);
      expect(result, isA<ScoreAccepted>());
      result as ScoreAccepted;
      expect(result.flightScore, '962.5');
      expect(result.nextRound, 3);
      expect(result.details?.official, isFalse);
      expect(result.details?.rawScore, '962.5');
      expect(result.details?.roundScore, '962.5');
      expect(result.details?.cumulativePenalty, isNull);
      expect(result.details?.enteredBy, 'Alex Rivera');
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

    test('a closed contest in the director envelope is a refusal', () async {
      final result = await _repository(
        (_) => _json(
          '{"error":{"code":"scoring_closed","message":"completed"}}',
          409,
        ),
      ).submitScore(_submission);
      expect(result, isA<ScoreRejected>());
      expect((result as ScoreRejected).code, 'scoring_closed');
    });

    test('a 401 with no body ends the session instead of queueing', () async {
      for (final body in ['', '<html>']) {
        final result = await _repository((_) => _json(body, 401))
            .submitScore(_submission);
        expect(result, isA<ScoreRejected>());
        expect((result as ScoreRejected).code, 'session_invalid');
      }
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
        MemoryGuestSessionStore(),
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
      PilotRoundStatus.upcoming,
    ]);
    expect(overview.rounds.first.enteredBy, 'you');
    expect(overview.nextRound, 2);
  });

  test('the overview carries the team the server names, or none', () async {
    final body =
        jsonDecode(_fixture('participant_overview')) as Map<String, dynamic>;
    expect(
      (await _repository(_fixtures).pilotOverview('c', 'p')).teamName,
      isNull,
    );
    (body['participant'] as Map<String, dynamic>)['team_name'] = 'Flyers';
    final overview = await _repository((_) => _json(jsonEncode(body)))
        .pilotOverview('c', 'p');
    expect(overview.teamName, 'Flyers');
  });

  test('closed scoring locks only rounds with no score', () async {
    final body =
        jsonDecode(_fixture('participant_overview')) as Map<String, dynamic>;
    body['access'] = {'code': 'scoring_closed', 'message': 'raw words'};
    final overview = await _repository((_) => _json(jsonEncode(body)))
        .pilotOverview('c', 'p');
    expect(overview.rounds.map((r) => r.status), [
      PilotRoundStatus.submitted,
      PilotRoundStatus.locked,
      PilotRoundStatus.locked,
    ]);
    expect(overview.access, ScoringAccess.closed);
    expect(
      overview.rounds.last.unavailableReason,
      'Scoring is closed for this contest.',
    );
  });

  test('a completed contest is read as completed, not as closed', () async {
    final body =
        jsonDecode(_fixture('participant_overview')) as Map<String, dynamic>;
    body['access'] = {'code': 'contest_completed', 'message': 'raw words'};
    final overview = await _repository((_) => _json(jsonEncode(body)))
        .pilotOverview('c', 'p');
    expect(overview.access, ScoringAccess.completed);
  });

  test('pages after the overview do not fetch the overview again', () async {
    final repository = _repository(_fixtures);
    await repository.entryContext('c', 'p', 2);
    await repository.groupResults('c', 'p', 1);
    await repository.results('c');
    expect(_requested, isNot(contains('/api/v1/self-scoring/overview')));
    expect(_requested, hasLength(3));
  });

  test('without a stored session the person starts again', () {
    final repository = _repository(_fixtures, signedIn: false);
    expect(
      repository.entryContext('c', 'p', 2),
      throwsA(isA<SessionEndedException>()),
    );
  });

  test('a bad link reads the same with an envelope or an empty body', () {
    for (final response in [
      _json('{"error":{"code":"invalid_invitation","message":"x"}}', 404),
      _json('', 404),
      _json('{"error":{"code":"expired","message":"x"}}', 410),
      _json('', 400),
    ]) {
      expect(
        _repository((_) => response).acceptInvitation('x'),
        throwsA(isA<InvalidInvitationException>()),
      );
    }
  });

  test('server message text never reaches the page', () async {
    final repository = _repository(
      (_) => _json(
        '{"code":"something_new","message":"SELECT * FROM secrets","request_id":"r"}',
        500,
      ),
    );
    await expectLater(
      repository.pilotOverview('c', 'p'),
      throwsA(
        isA<SelfScoreLoadException>().having(
          (e) => e.message,
          'message',
          isNot(contains('SELECT')),
        ),
      ),
    );
  });

  test('known refusals read as fixed sentences', () async {
    final repository = _repository(
      (_) => _json(
        '{"code":"scoring_closed","message":"raw server words","request_id":"r"}',
        409,
      ),
    );
    await expectLater(
      repository.pilotOverview('c', 'p'),
      throwsA(
        isA<SelfScoreLoadException>().having(
          (e) => e.message,
          'message',
          'Scoring is closed for this contest.',
        ),
      ),
    );
  });

  test('the entry context carries the draw and the landing table', () async {
    final entry = await _repository(_fixtures).entryContext('c', 'p', 2);
    expect(entry.pilotNumber, 7);
    expect(entry.formSupported, isTrue);
    // The fixture carries every field the server sends for F5J, so a renamed
    // key makes the form refuse the flight.
    expect(entry.fieldKeys, containsAll(EntryContext.knownFieldKeys));
    expect(entry.pilotName, 'Alex Rivera');
    expect(entry.group, 'B');
    expect(entry.lane, isNull);
    expect(entry.roundCount, 5);
    expect(entry.landingTable.map((l) => l.label), ['Good', 'Fair', 'Off']);
  });

  test('a stored score comes back with the entry context', () async {
    final body = jsonDecode(_fixture('entry_context')) as Map<String, dynamic>;
    expect(
      (await _repository(_fixtures).entryContext('c', 'p', 2)).submittedScore,
      isNull,
    );
    body['state'] = 'submitted';
    body['submitted_score'] = {
      'assignment_id': body['assignment_id'],
      'round': 2,
      'state': 'submitted',
      'revision': 1,
      'components': {'time_flown': 390.4, 'launch_height': 45},
      'entered_by': 'Alex Rivera',
      'entered_at': '2026-11-08T22:00:00Z',
      'flight_score': 912.5,
      'raw_score': 912.5,
      'round_score': 912.5,
      'cumulative_penalty': null,
      'validation_messages': [],
    };
    final entry = await _repository((_) => _json(jsonEncode(body)))
        .entryContext('c', 'p', 2);
    expect(entry.alreadySubmitted, isTrue);
    expect(entry.submittedScore!.components['time_flown'], 390.4);
    expect(entry.submittedScore!.flightScore, '912.5');
    expect(entry.submittedScore!.details!.enteredBy, 'Alex Rivera');
  });

  test('group results show zero, estimate and own rows', () async {
    final group = await _repository(_fixtures).groupResults('c', 'p', 1);
    expect(group.group, 'A');
    expect(group.latestRound, 2);
    final you = group.rows[0];
    expect(you.isYou, isTrue);
    expect(you.time, '9:00');
    expect(you.height, 45);
    expect(you.landing, 'Good 50');
    expect(you.rawScore, '962.5');
    expect(you.score, '962.5');
    expect(you.isEstimate, isFalse);
    final zero = group.rows[1];
    expect(zero.kind, GroupRowKind.zero);
    expect(zero.zeroReason, 'landed out');
    expect(zero.height, isNull);
    expect(zero.landing, isNull);
    final pending = group.rows[2];
    expect(pending.kind, GroupRowKind.noScore);
    expect(pending.score, '900');
    expect(pending.isEstimate, isTrue);
    expect(pending.height, isNull);
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
