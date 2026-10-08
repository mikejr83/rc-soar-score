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

  test('results(id) GETs the standings and their flags', () async {
    final results = ContestResults(asOfRound: 2, isStale: true);
    final client = clientFor((_) => body(results.toJson()));

    final read = await client.results(contestId);

    expect(read, results);
    expect(read.isPreliminary, isTrue);
    expect(seen.method, 'GET');
    expect(seen.url.path, '/api/v1/contests/${contestId.value}/results');
  });

  test('roundResults GETs one round', () async {
    final results = RoundResults(ordinal: 3, isStale: false, flights: []);
    final client = clientFor((_) => body(results.toJson()));

    expect(await client.roundResults(contestId, 3), results);
    expect(seen.method, 'GET');
    expect(
      seen.url.path,
      '/api/v1/contests/${contestId.value}/results/rounds/3',
    );
  });

  test('recalculateResults POSTs and decodes the new results', () async {
    final results = ContestResults(asOfRound: 1);
    final client = clientFor((_) => body(results.toJson()));

    expect(await client.recalculateResults(contestId), results);
    expect(seen.method, 'POST');
    expect(
      seen.url.path,
      '/api/v1/contests/${contestId.value}/results/recalculation',
    );
  });

  test('a contest that cannot be calculated is a 409 with its code', () async {
    final client = clientFor(
      (_) => body({
        'error': {
          'code': 'discipline_not_supported',
          'message': 'not yet',
          'requestId': 'r1',
        },
      }, 409),
    );

    await expectLater(
      client.recalculateResults(contestId),
      throwsA(
        isA<ApiHttpError>()
            .having((e) => e.statusCode, 'status', 409)
            .having((e) => e.error?.code, 'code', 'discipline_not_supported'),
      ),
    );
  });
}
