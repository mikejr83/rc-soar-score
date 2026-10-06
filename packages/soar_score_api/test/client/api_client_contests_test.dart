import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  group('ApiClient.contests()', () {
    final baseUrl = Uri.parse('http://localhost:8085');
    const jsonHeaders = <String, String>{
      'content-type': 'application/json; charset=utf-8',
    };
    final contest = Contest(
      id: Id.parse('019c0000-0000-7000-8000-000000000010'),
      name: 'Front Range ALES Open',
      startDateTime: DateTime.utc(2026, 10, 17, 14),
      endDateTime: DateTime.utc(2026, 10, 18, 22),
      timezone: 'America/Denver',
      createdAt: DateTime.utc(2026, 9),
      updatedAt: DateTime.utc(2026, 9),
    );

    ApiClient clientFor(http.Response Function(http.Request) respond) {
      final client = ApiClient(
        baseUrl: baseUrl,
        httpClient: MockClient((request) async => respond(request)),
      );
      addTearDown(client.close);
      return client;
    }

    test('parses the response into contests from /api/v1/contests', () async {
      late http.Request seen;
      final client = clientFor((request) {
        seen = request;
        return http.Response(
          jsonEncode({
            'contests': [contest.toJson()],
          }),
          200,
          headers: jsonHeaders,
        );
      });

      expect(await client.contests(), [contest]);
      expect(seen.method, 'GET');
      expect(seen.url, Uri.parse('http://localhost:8085/api/v1/contests'));
    });

    test('returns an empty list when there are no contests', () async {
      final client = clientFor(
        (_) => http.Response('{"contests":[]}', 200, headers: jsonHeaders),
      );

      expect(await client.contests(), isEmpty);
    });

    test('throws ApiHttpError for a non-2xx response', () async {
      final client = clientFor((_) => http.Response('nope', 500));

      expect(
        client.contests(),
        throwsA(
          isA<ApiHttpError>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('throws ApiNetworkError when the server is unreachable', () async {
      final client = ApiClient(
        baseUrl: baseUrl,
        httpClient: MockClient((_) async => throw http.ClientException('down')),
      );
      addTearDown(client.close);

      expect(client.contests(), throwsA(isA<ApiNetworkError>()));
    });

    test('throws ApiException for a malformed body', () async {
      final client = clientFor(
        (_) => http.Response('{"contests":[{"id":1}]}', 200),
      );

      expect(client.contests(), throwsA(isA<ApiException>()));
    });
  });
}
