import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_self_score/data/api_self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_repository.dart';
import 'package:soar_score_self_score/models/contests_view.dart';
import 'package:soar_score_self_score/models/entry_context.dart';
import 'package:soar_score_self_score/models/group_result_row.dart';
import 'package:soar_score_self_score/models/guest_session.dart';
import 'package:soar_score_self_score/models/officialization_policy.dart';
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
  '/api/v1/account/invitation-claims' => _json(
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

    test('a locked score in the director envelope is a refusal', () async {
      final result = await _repository(
        (_) => _json(
          '{"error":{"code":"score_locked","message":"locked by the director"}}',
          409,
        ),
      ).submitScore(_submission);
      expect(result, isA<ScoreRejected>());
      expect((result as ScoreRejected).code, 'score_locked');
    });

    test(
      'an unknown envelope code is still a refusal, not a lost connection',
      () async {
        final result = await _repository(
          (_) => _json(
            '{"error":{"code":"scoring_not_available","message":"no scores yet"}}',
            409,
          ),
        ).submitScore(_submission);
        expect(result, isA<ScoreRejected>());
        expect((result as ScoreRejected).code, 'scoring_not_available');
      },
    );

    test('a bare 409 with no readable code stays a lost connection', () {
      // A 409 the client cannot read is not proven to be a refusal, so it is
      // kept retryable: the server answers a refusal in one of the two
      // formats above, anything else is a failure, not a "do not retry".
      expect(
        _repository((_) => _json('locked', 409)).submitScore(_submission),
        throwsA(isA<SelfScoreOfflineException>()),
      );
    });

    test('a transient answer is offline even when it carries an envelope', () {
      for (final status in [408, 429]) {
        expect(
          _repository(
            (_) => _json(
              '{"error":{"code":"scoring_closed","message":"x"}}',
              status,
            ),
          ).submitScore(_submission),
          throwsA(isA<SelfScoreOfflineException>()),
        );
      }
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

  test('claiming a link gives the session the account acts in', () async {
    final session = await _repository(_fixtures).claimInvitation('abc');
    expect(session.pilotName, 'Alex Rivera');
    expect(session.pilotId, '0192f6a0-0000-7000-8000-000000000002');
  });

  test('claiming a pilot another account holds says so', () {
    final repository = _repository(
      (_) => _json('{"error":{"code":"already_linked"}}', 409),
    );
    expect(
      repository.claimInvitation('abc'),
      throwsA(isA<PilotAlreadyLinkedException>()),
    );
  });

  test('another 409 on a claim is not "already linked"', () async {
    for (final code in ['invitations_not_available', 'backend_only', '']) {
      final repository = _repository(
        (_) => _json(code.isEmpty ? '' : '{"error":{"code":"$code"}}', 409),
      );
      await expectLater(
        repository.claimInvitation('abc'),
        throwsA(
          allOf(
            isA<SelfScoreLoadException>(),
            isNot(isA<PilotAlreadyLinkedException>()),
          ),
        ),
        reason: code,
      );
    }
  });

  test('claiming with a refused sign-in says the sign-in expired', () {
    final repository = _repository((_) => _json('{}', 401));
    expect(
      repository.claimInvitation('abc'),
      throwsA(isA<AccountSignInExpiredException>()),
    );
  });

  test('claiming with an account that cannot link is not the link', () {
    final repository = _repository(
      (_) => _json('{"error":{"code":"link_not_found"}}', 404),
    );
    expect(
      repository.claimInvitation('abc'),
      throwsA(isA<AccountCannotLinkException>()),
    );
  });

  test('claiming a bad link is the invalid-link failure', () {
    final repository = _repository(
      (_) => _json(_fixture('error_invalid_invitation'), 404),
    );
    expect(
      repository.claimInvitation('nope'),
      throwsA(isA<InvalidInvitationException>()),
    );
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

  test('a retired pilot reads as retired, not as a scored row', () async {
    final body = jsonDecode(_fixture('group_results')) as Map<String, dynamic>;
    final rows = (body['rows'] as List).cast<Map<String, dynamic>>();
    rows[2]['state'] = 'retired';
    final group = await _repository((_) => _json(jsonEncode(body)))
        .groupResults('c', 'p', 1);
    expect(group.rows[2].kind, GroupRowKind.retired);
  });

  test('a zero reason keeps its code for the screen to label', () async {
    final body = jsonDecode(_fixture('group_results')) as Map<String, dynamic>;
    for (final row in (body['rows'] as List).cast<Map<String, dynamic>>()) {
      if (row['zero_reason'] != null) row['zero_reason'] = 'out_of_bounds';
    }
    final group = await _repository((_) => _json(jsonEncode(body)))
        .groupResults('c', 'p', 1);
    expect(group.rows[1].zeroReason, 'out_of_bounds');
  });

  test(
    'group results show the components, points and distinct raw/score',
    () async {
      final group = await _repository(_fixtures).groupResults('c', 'p', 1);
      expect(group.group, 'A');
      expect(group.latestRound, 2);
      final you = group.rows[0];
      expect(you.isYou, isTrue);
      expect(you.time, '9:00');
      expect(you.height, 45);
      expect(you.landing, 50);
      expect(you.rawScore, '975');
      expect(you.score, '962.5');
      final zero = group.rows[1];
      expect(zero.kind, GroupRowKind.zero);
      expect(zero.zeroReason, 'landed out');
      expect(zero.height, isNull);
      expect(zero.landing, isNull);
      // An unscored flight is not in the standings, so it shows no value even
      // though the server carries an estimate.
      final pending = group.rows[2];
      expect(pending.kind, GroupRowKind.noScore);
      expect(pending.score, isNull);
      expect(pending.landing, isNull);
      expect(pending.height, isNull);
    },
  );

  test(
    'a known rule reaches both results; an unknown one gives null',
    () async {
      final known = _repository(_fixtures);
      expect(
        (await known.groupResults('c', 'p', 1)).policy,
        OfficializationPolicy.endOfRound,
      );
      expect(
        (await known.results('c')).policy,
        OfficializationPolicy.endOfRound,
      );

      String unknown(String name) =>
          _fixture(name).replaceFirst('"EndOfRound"', '"EndOfSeason"');
      final newer = _repository(
        (request) => switch (request.url.path) {
          '/api/v1/self-scoring/rounds/1/group-results' => _json(
            unknown('group_results'),
          ),
          '/api/v1/self-scoring/results' => _json(unknown('overall_results')),
          _ => _fixtures(request),
        },
      );
      expect((await newer.groupResults('c', 'p', 1)).policy, isNull);
      expect((await newer.results('c')).policy, isNull);
    },
  );

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

  group('Is this you', () {
    const candidateId = '019c0000-0000-7000-8000-00000000c101';
    const linkBody =
        '{"id":"$candidateId","pilot_name":"Pat Pilot","status":"Confirmed",'
        '"origin":"EmailMatch","confirmed_at":"2026-10-17T14:00:00.000Z",'
        '"ended_at":null}';

    test('candidates read as pilot name and dated contests', () async {
      final repository = _repository((request) {
        expect(request.url.path, '/api/v1/account/link-candidates');
        return _json(
          '{"candidates":[{"id":"$candidateId","first_name":"Pat",'
          '"last_name":"Pilot","contests":[{"name":"Spring Open",'
          '"start_date_time":"2026-10-17T14:00:00.000Z",'
          '"end_date_time":"2026-10-18T22:00:00.000Z",'
          '"start_date":"2026-10-17","end_date":"2026-10-18",'
          '"timezone":"America/Denver","host":null,"city":null,'
          '"state":null,"country":null}]}]}',
        );
      });

      final result = await repository.linkCandidates();

      expect(result.single.id, candidateId);
      expect(result.single.pilotName, 'Pat Pilot');
      expect(result.single.contests.single.name, 'Spring Open');
      expect(
        result.single.contests.single.startDate,
        DateTime.utc(2026, 10, 17),
      );
      expect(result.single.contests.single.endDate, DateTime.utc(2026, 10, 18));
    });

    test('a one-day contest shows one date', () async {
      final repository = _repository(
        (_) => _json(
          '{"candidates":[{"id":"$candidateId","first_name":"Pat",'
          '"last_name":"Pilot","contests":[{"name":"Spring Open",'
          '"start_date_time":"2026-10-17T14:00:00.000Z",'
          '"end_date_time":"2026-10-17T22:00:00.000Z",'
          '"start_date":"2026-10-17","end_date":"2026-10-17",'
          '"timezone":"America/Denver"}]}]}',
        ),
      );
      final result = await repository.linkCandidates();
      final day = result.single.contests.single;
      expect(day.startDate, DateTime.utc(2026, 10, 17));
      expect(day.endDate, day.startDate);
    });

    test(
      'a day in the contest zone shows once, whatever the UTC dates',
      () async {
        // Sydney, Saturday 9 am to 3 pm (daylight saving): Friday 22:00 to
        // Saturday 04:00 UTC, two UTC dates for one local day.
        final repository = _repository(
          (_) => _json(
            '{"candidates":[{"id":"$candidateId","first_name":"Pat",'
            '"last_name":"Pilot","contests":[{"name":"Sydney Open",'
            '"start_date_time":"2026-11-27T22:00:00.000Z",'
            '"end_date_time":"2026-11-28T04:00:00.000Z",'
            '"start_date":"2026-11-28","end_date":"2026-11-28",'
            '"timezone":"Australia/Sydney"}]}]}',
          ),
        );
        final result = await repository.linkCandidates();
        final day = result.single.contests.single;
        expect(day.startDate, DateTime.utc(2026, 11, 28));
        expect(day.endDate, day.startDate);
      },
    );

    test('confirm and decline post to the candidate', () async {
      final seen = <String>[];
      final repository = _repository((request) {
        seen.add('${request.method} ${request.url.path}');
        return request.url.path.endsWith('/confirm')
            ? _json(linkBody)
            : http.Response('', 204);
      });

      await repository.confirmLinkCandidate(candidateId);
      await repository.declineLinkCandidate(candidateId);

      expect(seen, [
        'POST /api/v1/account/link-candidates/$candidateId/confirm',
        'POST /api/v1/account/link-candidates/$candidateId/decline',
      ]);
    });

    test('409 and 404 end the card, other failures may pass', () async {
      LinkCandidateGoneReason? reasonOf(Object? error) =>
          error is LinkCandidateGoneException ? error.reason : null;

      const taken409 = '{"error":{"code":"already_linked","message":"x"}}';
      const gone404 = '{"error":{"code":"link_not_found","message":"x"}}';
      final taken = _repository((_) => _json(taken409, 409));
      await expectLater(
        taken.confirmLinkCandidate(candidateId),
        throwsA(
          predicate(
            (e) => reasonOf(e) == LinkCandidateGoneReason.alreadyLinked,
          ),
        ),
      );
      final gone = _repository((_) => _json(gone404, 404));
      await expectLater(
        gone.declineLinkCandidate(candidateId),
        throwsA(
          predicate((e) => reasonOf(e) == LinkCandidateGoneReason.notAvailable),
        ),
      );
      final down = _repository((_) => _json('{}', 500));
      await expectLater(
        down.confirmLinkCandidate(candidateId),
        throwsA(
          isA<SelfScoreLoadException>().having(
            (e) => e is LinkCandidateGoneException,
            'gone',
            false,
          ),
        ),
      );
    });

    test(
      'other 409 and 404 answers keep the card eligible for retry',
      () async {
        for (final (status, code) in [
          (409, 'invitations_not_available'),
          (409, 'backend_only'),
          (404, 'not_found'),
        ]) {
          final repository = _repository(
            (_) => _json('{"error":{"code":"$code","message":"x"}}', status),
          );
          await expectLater(
            repository.confirmLinkCandidate(candidateId),
            throwsA(
              isA<SelfScoreLoadException>().having(
                (e) => e is LinkCandidateGoneException,
                'gone for $status $code',
                false,
              ),
            ),
          );
        }
      },
    );

    test('an expired account token does not end the guest session', () async {
      final repository = _repository((_) => _json('{}', 401));
      await expectLater(
        repository.linkCandidates(),
        throwsA(
          isA<SelfScoreLoadException>().having(
            (e) => e is SessionEndedException,
            'session ended',
            false,
          ),
        ),
      );
    });

    test('a 401 on any account route is the sign-in ending (#546)', () async {
      // Not "could not reach the server": the pages offer signing in again.
      final repository = _repository((_) => _json('{}', 401));
      final calls = <String, Future<Object?> Function()>{
        'link candidates': repository.linkCandidates,
        'confirm': () => repository.confirmLinkCandidate(
          '0192f6a0-0000-7000-8000-000000000002',
        ),
        'decline': () => repository.declineLinkCandidate(
          '0192f6a0-0000-7000-8000-000000000002',
        ),
        'own directory': repository.ownDirectory,
        'delete entry': repository.deleteOwnDirectory,
        'links': repository.accountLinks,
        'end link': () =>
            repository.endAccountLink('0192f6a0-0000-7000-8000-000000000002'),
      };
      for (final entry in calls.entries) {
        await expectLater(
          entry.value(),
          throwsA(isA<SignedOutException>()),
          reason: entry.key,
        );
      }
    });
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

  group('past contests', () {
    String page({String? results, int? next}) => jsonEncode({
      'contests': [
        {
          'participation_id': '019c0000-0000-7000-8000-00000000d201',
          'contest_id': '019c0000-0000-7000-8000-000000000045',
          'contest_name': 'Spring Open',
          'start_date_time': '2026-04-11T14:00:00.000Z',
          'end_date_time': '2026-04-12T22:00:00.000Z',
          'start_date': '2026-04-11',
          'end_date': '2026-04-12',
          'timezone': 'America/Denver',
          'host': null,
          'city': 'Boulder',
          'state': 'CO',
          'country': null,
          'public_results_url': results,
        },
      ],
      'next_offset': next,
    });

    test('reads a page and asks for the offset', () async {
      final result = await _repository((request) {
        expect(request.url.path, '/api/v1/account/history');
        expect(request.url.queryParameters['offset'], '50');
        return _json(
          page(results: 'https://rcsoarscore.com/results/x', next: 100),
        );
      }).pastContests(offset: 50);

      final contest = result.contests.single;
      expect(contest.name, 'Spring Open');
      expect(contest.startDate, DateTime.utc(2026, 4, 11));
      expect(contest.endDate, DateTime.utc(2026, 4, 12));
      expect(contest.location, 'Boulder, CO');
      expect(
        contest.publicResultsUrl,
        Uri.parse('https://rcsoarscore.com/results/x'),
      );
      expect(result.nextOffset, 100);
    });

    test('an address that is not a web page is no address', () async {
      final result = await _repository(
        (_) => _json(page(results: 'javascript:alert(1)')),
      ).pastContests();

      expect(result.contests.single.publicResultsUrl, isNull);
      expect(result.nextOffset, isNull);
    });

    test('a 401 is the sign-in ending, not the guest session', () async {
      await expectLater(
        _repository((_) => _json('', 401)).pastContests(),
        throwsA(isA<SignedOutException>()),
      );
    });
  });

  group('contests', () {
    const participation = '019c0000-0000-7000-8000-00000000d201';

    String list(Map<String, Object?> extra) => jsonEncode({
      'participations': [
        {
          'participation_id': participation,
          'contest_id': '019c0000-0000-7000-8000-000000000045',
          'contest_name': 'Spring Open',
          'start_date_time': '2026-10-17T14:00:00.000Z',
          'end_date_time': '2026-10-19T04:00:00.000Z',
          'start_date': '2026-10-17',
          'end_date': '2026-10-18',
          'timezone': 'America/Denver',
          'phase': 'in_progress',
          'read_only': false,
          'host': null,
          'city': 'Denver',
          'state': 'CO',
          'country': ' ',
          'public_results_url': null,
          ...extra,
        },
      ],
    });

    test('reads the list, with dates as the contest wrote them', () async {
      final view = await _repository((request) {
        expect(request.url.path, '/api/v1/account/participations');
        return _json(
          list({'public_results_url': 'https://rcsoarscore.com/results/x'}),
        );
      }).contests();

      final contest = view.contests.single;
      expect(contest.participationId, participation);
      expect(contest.name, 'Spring Open');
      expect(contest.startDate, DateTime.utc(2026, 10, 17));
      expect(contest.endDate, DateTime.utc(2026, 10, 18));
      expect(contest.phase, ContestPhase.inProgress);
      expect(contest.location, 'Denver, CO');
      expect(
        contest.publicResultsUrl,
        Uri.parse('https://rcsoarscore.com/results/x'),
      );
    });

    test('an address that is not a web page is no address', () async {
      final view = await _repository(
        (_) => _json(list({'public_results_url': 'javascript:alert(1)'})),
      ).contests();

      expect(view.contests.single.publicResultsUrl, isNull);
    });

    test('a 401 is the sign-in ending, not the guest session', () async {
      await expectLater(
        _repository((_) => _json('', 401)).contests(),
        throwsA(isA<SignedOutException>()),
      );
    });

    test('opening a contest gives the session the server sent', () async {
      final session = await _repository((request) {
        expect(
          request.url.path,
          '/api/v1/account/participations/$participation/session',
        );
        expect(request.method, 'POST');
        return _json(_fixture('resolve_invitation_response'));
      }).openContest(participation);

      expect(session.pilotName, 'Alex Rivera');
      expect(session.token, 'example-session-token');
    });

    test('a contest that left the list is said so', () async {
      await expectLater(
        _repository((_) => _json('{"error":{"code":"link_not_found"}}', 404))
            .openContest(participation),
        throwsA(isA<ContestNotOnListException>()),
      );
    });

    test('a 404 with no link_not_found code is not "left the list"', () async {
      // A wrong address or a proxy error page, not the server's answer.
      for (final body in ['{}', '<html>', '{"error":{"code":"other"}}']) {
        await expectLater(
          _repository((_) => _json(body, 404)).openContest(participation),
          throwsA(
            isA<SelfScoreLoadException>().having(
              (e) => e is ContestNotOnListException,
              'left the list',
              false,
            ),
          ),
          reason: body,
        );
      }
    });

    test('a 401 opening a contest is the sign-in ending', () async {
      await expectLater(
        _repository((_) => _json('', 401)).openContest(participation),
        throwsA(isA<SignedOutException>()),
      );
    });
  });
}
