import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  final contestId = Id.parse('019c0000-0000-7000-8000-0000000000c1');
  const jsonHeaders = <String, String>{
    'content-type': 'application/json; charset=utf-8',
  };
  final requestJson = <String, Object?>{
    'id': '019c0000-0000-7000-8000-0000000000d1',
    'publication_id': '019c0000-0000-7000-8000-000000000030',
    'requested_by': '019c0000-0000-7000-8000-000000000001',
    'trigger': 'owner_request',
    'reason': 'Wrong contest',
    'requested_at': '2026-11-03T12:00:00.000Z',
    'state': 'pending',
    'decided_by': null,
    'decided_at': null,
    'decision_note': null,
  };

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

  http.Response body(Object json, [int status = 200]) =>
      http.Response(jsonEncode(json), status, headers: jsonHeaders);

  final base = '/api/v1/contests/${contestId.value}/publication';

  test('requestDelisting posts the reason and reads the request', () async {
    final client = clientFor((_) => body(requestJson, 201));

    final made = await client.requestDelisting(contestId, reason: 'Wrong');

    expect(seen.method, 'POST');
    expect(seen.url.path, '$base/delist-requests');
    expect(jsonDecode(seen.body), {'reason': 'Wrong'});
    expect(made.state, DelistState.pending);
    expect(made.reason, 'Wrong contest');
  });

  test('currentDelistRequest reads the latest request', () async {
    final client = clientFor((_) => body(requestJson));

    final read = await client.currentDelistRequest(contestId);

    expect(seen.method, 'GET');
    expect(seen.url.path, '$base/delist-requests/current');
    expect(read.isPending, isTrue);
  });

  test('withdrawDelistRequest deletes the current request', () async {
    final client = clientFor(
      (_) => body({...requestJson, 'state': 'withdrawn'}),
    );

    final withdrawn = await client.withdrawDelistRequest(contestId);

    expect(seen.method, 'DELETE');
    expect(seen.url.path, '$base/delist-requests/current');
    expect(withdrawn.state, DelistState.withdrawn);
  });

  test('publicationProjections reads the list and sends the paging', () async {
    final client = clientFor(
      (_) => body({
        'projections': [
          {
            'id': '019c0000-0000-7000-8000-0000000000e1',
            'projection_revision': 2,
            'contest_revision': 5,
            'published_at': '2026-11-03T12:00:00.000Z',
            'published_by': '019c0000-0000-7000-8000-000000000001',
            'publisher_kind': 'system',
          },
        ],
      }),
    );

    final list = await client.publicationProjections(
      contestId,
      limit: 10,
      offset: 5,
    );

    expect(seen.url.path, '$base/projections');
    expect(seen.url.queryParameters, {'limit': '10', 'offset': '5'});
    expect(list.single.projectionRevision, 2);
    expect(list.single.isBySystem, isTrue);
    expect(
      list.single.publishedBy,
      Id.parse('019c0000-0000-7000-8000-000000000001'),
    );
  });

  test('a refusal is an ApiHttpError', () async {
    final client = clientFor(
      (_) => body({
        'error': {
          'code': 'publishing_not_available',
          'message': 'no',
          'requestId': 'r1',
        },
      }, 409),
    );

    await expectLater(
      client.requestDelisting(contestId),
      throwsA(isA<ApiHttpError>().having((e) => e.statusCode, 'status', 409)),
    );
  });
}
