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
  final publicationId = Id.parse('019c0000-0000-7000-8000-000000000030');
  final summaryJson = <String, Object?>{
    'publication_id': publicationId.value,
    'published_at': '2026-10-17T14:00:00.000Z',
    'projection_revision': 2,
    'contest': {'name': 'Front Range ALES Open', 'timezone': 'America/Denver'},
    'discipline_type': 'F5J',
  };
  final publicationJson = <String, Object?>{
    ...summaryJson,
    'visibility': 'Public',
    'calculation_version': 'f5j-1',
    'results_hidden_through_round': null,
    'participants': [
      {'key': 'p1', 'display_name': 'A. Pilot', 'details': null},
    ],
    'teams': <Object?>[],
    'matrix': {'rounds': <Object?>[]},
    'scores': <Object?>[],
    'standings': {
      'rounds': [
        {'ordinal': 1},
      ],
    },
    'calculation': null,
  };

  late http.Request seen;

  ApiClient clientFor(
    http.Response Function(http.Request) respond, {
    TokenProvider? tokenProvider,
  }) {
    final client = ApiClient(
      baseUrl: baseUrl,
      httpClient: MockClient((request) async {
        seen = request;
        return respond(request);
      }),
      tokenProvider: tokenProvider,
    );
    addTearDown(client.close);
    return client;
  }

  http.Response body(Object json, [int status = 200]) =>
      http.Response(jsonEncode(json), status, headers: jsonHeaders);

  http.Response notAvailable() => body({
    'error': {
      'code': 'publishing_not_available',
      'message': 'this server does not publish contests',
      'requestId': 'r1',
    },
  }, 409);

  group('publicPublications', () {
    test('GETs the listing and decodes the summaries', () async {
      final client = clientFor(
        (_) => body({
          'publications': [summaryJson],
        }),
      );

      final read = await client.publicPublications();

      expect(read, hasLength(1));
      expect(read.single.publicationId, publicationId);
      expect(read.single.publishedAt, DateTime.utc(2026, 10, 17, 14));
      expect(read.single.projectionRevision, 2);
      expect(read.single.contest['name'], 'Front Range ALES Open');
      expect(read.single.disciplineType, 'F5J');
      expect(seen.method, 'GET');
      expect(seen.url, Uri.parse('http://localhost:8085/public/publications'));
    });

    test('passes limit and offset as query parameters', () async {
      final client = clientFor((_) => body({'publications': <Object?>[]}));

      expect(await client.publicPublications(limit: 10, offset: 20), isEmpty);
      expect(seen.url.path, '/public/publications');
      expect(seen.url.queryParameters, {'limit': '10', 'offset': '20'});
    });

    test('sends no Authorization header without a token', () async {
      final client = clientFor(
        (_) => body({'publications': <Object?>[]}),
        tokenProvider: () async => null,
      );

      await client.publicPublications();

      expect(seen.headers, isNot(contains('authorization')));
    });

    test('a server that does not publish is a 409 with its code', () async {
      final client = clientFor((_) => notAvailable());

      await expectLater(
        client.publicPublications(),
        throwsA(
          isA<ApiHttpError>()
              .having((e) => e.statusCode, 'status', 409)
              .having((e) => e.error?.code, 'code', 'publishing_not_available'),
        ),
      );
    });
  });

  group('publicPublication', () {
    test('GETs one publication and keeps the nested data as served', () async {
      final client = clientFor((_) => body(publicationJson));

      final read = await client.publicPublication(publicationId);

      expect(read.publicationId, publicationId);
      expect(read.visibility, 'Public');
      expect(read.calculationVersion, 'f5j-1');
      expect(read.resultsHiddenThroughRound, isNull);
      expect(read.participants, publicationJson['participants']);
      expect(read.matrix, publicationJson['matrix']);
      expect(read.standings, publicationJson['standings']);
      expect(read.calculation, isNull);
      expect(seen.method, 'GET');
      expect(seen.url.path, '/public/publications/${publicationId.value}');
      expect(seen.headers, isNot(contains('authorization')));
    });

    test('an unknown or delisted publication is a 404', () async {
      final client = clientFor(
        (_) => body({
          'error': {'code': 'not_found', 'message': 'no', 'requestId': 'r2'},
        }, 404),
      );

      await expectLater(
        client.publicPublication(publicationId),
        throwsA(
          isA<ApiHttpError>().having((e) => e.statusCode, 'status', 404),
        ),
      );
    });

    test('a server that does not publish is a 409 with its code', () async {
      final client = clientFor((_) => notAvailable());

      await expectLater(
        client.publicPublication(publicationId),
        throwsA(
          isA<ApiHttpError>()
              .having((e) => e.statusCode, 'status', 409)
              .having((e) => e.error?.code, 'code', 'publishing_not_available'),
        ),
      );
    });
  });
}
