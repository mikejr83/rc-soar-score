import 'dart:convert';
import 'dart:io';

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

  test('accountHistory reads a page and sends its paging', () async {
    final client = clientFor(
      (_) => json({
        'contests': [
          {
            'participation_id': '019c0000-0000-7000-8000-00000000d201',
            'contest_id': '019c0000-0000-7000-8000-000000000045',
            'contest_name': 'Spring Open',
            'start_date_time': '2026-10-17T14:00:00.000Z',
            'end_date_time': '2026-10-18T22:00:00.000Z',
            'start_date': '2026-10-17',
            'end_date': '2026-10-18',
            'timezone': 'America/Denver',
            'host': null,
            'city': 'Denver',
            'state': null,
            'country': null,
            'public_results_url': 'https://rcsoarscore.com/results/contests/x',
          },
        ],
        'next_offset': 20,
      }),
    );

    final page = await client.accountHistory(limit: 20, offset: 20);

    expect(seen.method, 'GET');
    expect(seen.url.path, '/api/v1/account/history');
    expect(seen.url.queryParameters, {'limit': '20', 'offset': '20'});
    expect(page.nextOffset, 20);
    expect(page.contests.single.contestName, 'Spring Open');
    expect(page.contests.single.city, 'Denver');
    expect(
      page.contests.single.publicResultsUrl,
      'https://rcsoarscore.com/results/contests/x',
    );
  });

  test('accountHistory with no paging sends no query', () async {
    final client = clientFor(
      (_) => json({'contests': [], 'next_offset': null}),
    );

    final page = await client.accountHistory();

    expect(seen.url.hasQuery, isFalse);
    expect(page.contests, isEmpty);
    expect(page.nextOffset, isNull);
  });

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
            'start_date': '2026-10-17',
            'end_date': '2026-10-18',
            'timezone': 'America/Denver',
            'phase': 'in_progress',
            'read_only': false,
            'host': null,
            'city': 'Denver',
            'state': null,
            'country': null,
            'public_results_url': 'https://rcsoarscore.com/results/contests/x',
          },
        ],
      }),
    );

    final result = await client.accountParticipations();

    expect(seen.method, 'GET');
    expect(seen.url.path, '/api/v1/account/participations');
    expect(result.participations.single.contestName, 'Spring Open');
    expect(result.participations.single.startDate, '2026-10-17');
    expect(
      result.participations.single.publicResultsUrl,
      'https://rcsoarscore.com/results/contests/x',
    );
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
                'start_date': '2026-10-17',
                'end_date': '2026-10-18',
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

  Map<String, dynamic> resolveFixture() => jsonDecode(
    File('fixtures/self_scoring/resolve_invitation_response.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;

  test('claimInvitation posts the credential with the account token', () async {
    final client = clientFor((_) => json(resolveFixture()));

    final session = await client.claimInvitation(
      const ResolveInvitationRequest(credential: 'abc'),
    );

    expect(seen.method, 'POST');
    expect(seen.url.path, '/api/v1/account/invitation-claims');
    expect(jsonDecode(seen.body), {'credential': 'abc', 'device_id': null});
    expect(session.sessionToken, isNotNull);
  });

  test('claimInvitation: a link that does not open and a held pilot', () async {
    var client = clientFor(
      (_) => json({
        'error': {'code': 'invalid_invitation', 'message': 'x'},
      }, 404),
    );
    await expectLater(
      client.claimInvitation(const ResolveInvitationRequest(credential: 'x')),
      throwsA(isA<ApiHttpError>().having((e) => e.statusCode, 'status', 404)),
    );

    client = clientFor(
      (_) => json({
        'error': {'code': 'already_linked', 'message': 'x'},
      }, 409),
    );
    await expectLater(
      client.claimInvitation(const ResolveInvitationRequest(credential: 'x')),
      throwsA(isA<ApiHttpError>().having((e) => e.statusCode, 'status', 409)),
    );
  });

  test('openAccountParticipation posts to the participation', () async {
    final client = clientFor((_) => json(resolveFixture()));
    final participation = Id.parse('019c0000-0000-7000-8000-00000000d201');

    await client.openAccountParticipation(participation.value);

    expect(seen.method, 'POST');
    expect(
      seen.url.path,
      '/api/v1/account/participations/${participation.value}/session',
    );
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

  group('directory (#653)', () {
    final entry = Id.parse('019c0000-0000-7000-8000-00000000a101');
    final profile = Id.parse('019c0000-0000-7000-8000-00000000b101');
    final match = {
      'entry_id': entry.value,
      'first_name': 'Pat',
      'last_name': 'Pilot',
      'club': null,
      'fai_number': 'F1',
      'national_org_id': null,
      'city': null,
      'state': null,
      'country': null,
      'email': null,
      'email_available': true,
    };

    test('lookupDirectory posts the key and value', () async {
      final client = clientFor(
        (_) => json({
          'results': [match],
        }),
      );

      final response = await client.lookupDirectory(
        const DirectoryLookupRequest(
          key: DirectoryLookupKeyDto.faiNumber,
          value: 'F1',
        ),
      );

      expect(seen.method, 'POST');
      expect(seen.url.path, '/api/v1/directory/lookups');
      expect(jsonDecode(seen.body), {'key': 'fai_number', 'value': 'F1'});
      expect(seen.url.query, isEmpty);
      expect(response.results.single.entryId, entry);
      expect(response.results.single.email, isNull);
      expect(response.results.single.emailAvailable, isTrue);
    });

    test('copy and refresh post the entry and profile ids', () async {
      final client = clientFor((_) => json(match));
      final request = DirectoryCopyRequest(entryId: entry, profileId: profile);

      final copied = await client.copyDirectoryEntry(request);
      expect(seen.url.path, '/api/v1/directory/copies');
      expect(jsonDecode(seen.body), {
        'entry_id': entry.value,
        'profile_id': profile.value,
      });
      final refreshed = await client.refreshDirectoryEntry(request);
      expect(seen.url.path, '/api/v1/directory/refreshes');

      expect(copied.firstName, 'Pat');
      expect(refreshed.faiNumber, 'F1');
    });

    test('a refused copy is an ApiHttpError', () async {
      final client = clientFor(
        (_) => json({
          'error': {'code': 'link_not_found', 'message': 'gone'},
        }, 404),
      );

      await expectLater(
        client.copyDirectoryEntry(
          DirectoryCopyRequest(entryId: entry, profileId: profile),
        ),
        throwsA(isA<ApiHttpError>().having((e) => e.statusCode, 'status', 404)),
      );
    });
  });
}
