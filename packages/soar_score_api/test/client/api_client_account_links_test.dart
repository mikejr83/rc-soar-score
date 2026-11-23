import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  final candidate = Id.parse('019c0000-0000-7000-8000-00000000c101');
  final link = Id.parse('019c0000-0000-7000-8000-00000000e101');
  late http.Request seen;

  ApiClient clientFor(http.Response Function(http.Request) respond) {
    final client = ApiClient(
      baseUrl: Uri.parse('http://localhost:8085'),
      httpClient: MockClient((request) async {
        seen = request;
        return respond(request);
      }),
    );
    addTearDown(client.close);
    return client;
  }

  http.Response json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  final linkJson = {
    'id': link.value,
    'pilot_name': 'Pat Pilot',
    'status': 'Confirmed',
    'origin': 'EmailMatch',
    'confirmed_at': '2026-11-22T12:00:00.000Z',
    'ended_at': null,
  };

  test('accountParticipations reads the list', () async {
    final client = clientFor(
      (_) => json({
        'participations': [
          {
            'participation_id': '019c0000-0000-7000-8000-00000000d201',
            'contest_id': '019c0000-0000-7000-8000-000000000045',
            'contest_name': 'Spring Open',
            'start_date_time': '2026-10-17T14:00:00.000Z',
            'end_date_time': '2026-10-18T22:00:00.000Z',
            'timezone': 'America/Denver',
            'phase': 'in_progress',
            'read_only': false,
            'host': null,
            'city': 'Denver',
            'state': null,
            'country': null,
          },
        ],
      }),
    );

    final result = await client.accountParticipations();

    expect(seen.method, 'GET');
    expect(seen.url.path, '/api/v1/account/participations');
    expect(result.participations.single.contestName, 'Spring Open');
    expect(
      result.participations.single.phase,
      AccountParticipationPhase.inProgress,
    );
  });

  test('linkCandidates reads the matches', () async {
    final client = clientFor(
      (_) => json({
        'candidates': [
          {
            'id': candidate.value,
            'first_name': 'Pat',
            'last_name': 'Pilot',
            'contests': [
              {
                'name': 'Spring Open',
                'start_date_time': '2026-10-17T14:00:00.000Z',
                'end_date_time': '2026-10-18T22:00:00.000Z',
                'timezone': 'America/Denver',
                'host': null,
                'city': null,
                'state': null,
                'country': null,
              },
            ],
          },
        ],
      }),
    );

    final result = await client.linkCandidates();

    expect(seen.url.path, '/api/v1/account/link-candidates');
    expect(result.candidates.single.id, candidate);
    expect(result.candidates.single.contests.single.name, 'Spring Open');
  });

  test('confirmLinkCandidate posts to the candidate', () async {
    final client = clientFor((_) => json(linkJson));

    final result = await client.confirmLinkCandidate(candidate);

    expect(seen.method, 'POST');
    expect(
      seen.url.path,
      '/api/v1/account/link-candidates/${candidate.value}/confirm',
    );
    expect(result.status, ParticipantLinkStatus.confirmed);
    expect(result.origin, ParticipantLinkOrigin.emailMatch);
  });

  test('declineLinkCandidate accepts the empty answer', () async {
    final client = clientFor((_) => http.Response('', 204));

    await client.declineLinkCandidate(candidate);

    expect(seen.method, 'POST');
    expect(
      seen.url.path,
      '/api/v1/account/link-candidates/${candidate.value}/decline',
    );
  });

  test('accountLinks and endAccountLink', () async {
    var client = clientFor(
      (_) => json({
        'links': [linkJson],
      }),
    );
    expect((await client.accountLinks()).links.single.pilotName, 'Pat Pilot');
    expect(seen.url.path, '/api/v1/account/links');

    client = clientFor(
      (_) => json({
        ...linkJson,
        'status': 'Ended',
        'ended_at': '2026-11-23T12:00:00.000Z',
      }),
    );
    final ended = await client.endAccountLink(link);
    expect(seen.method, 'POST');
    expect(seen.url.path, '/api/v1/account/links/${link.value}/end');
    expect(ended.status, ParticipantLinkStatus.ended);
  });

  test('already_linked is a 409 ApiHttpError', () async {
    final client = clientFor(
      (_) => json({
        'error': {'code': 'already_linked', 'message': 'x'},
      }, 409),
    );

    await expectLater(
      client.confirmLinkCandidate(candidate),
      throwsA(isA<ApiHttpError>().having((e) => e.statusCode, 'status', 409)),
    );
  });
}
