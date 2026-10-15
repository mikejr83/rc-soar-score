import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  final baseUrl = Uri.parse('http://localhost:8086');
  const jsonHeaders = <String, String>{
    'content-type': 'application/json; charset=utf-8',
  };

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

  test(
    'importGliderScore posts the request and decodes the snapshot',
    () async {
      final client = clientFor(
        (_) => body({
          'schema': 'gs-import/v1',
          'id': '019c0000-0000-7000-8000-000000000a01',
          'sourceDbFile': 'GliderScoreData.mdb',
          'tables': [
            {
              'name': 'Scores',
              'rowCount': 2,
              'rowCapExceeded': false,
              'rows': [
                {'Pilot': 'Ann', 'Score': 41.5},
                {'Pilot': 'Bob', 'Score': 39},
              ],
            },
            {
              'name': 'Pilots',
              'rowCount': 1,
              'rowCapExceeded': false,
              'rows': [
                {'Name': 'Ann', 'License': 1234},
              ],
            },
          ],
        }, 201),
      );

      final result = await client.importGliderScore(
        'C:\\GliderScoreData.mdb',
        tables: ['Scores', 'Pilots'],
      );

      expect(seen.method, 'POST');
      expect(seen.url.path, '/api/v1/imports/gliderscore');
      expect(jsonDecode(seen.body), {
        'path': r'C:\GliderScoreData.mdb',
        'tables': ['Scores', 'Pilots'],
      });
      expect(result.id, Id.parse('019c0000-0000-7000-8000-000000000a01'));
      expect(result.sourceDbFile, 'GliderScoreData.mdb');
      expect(result.tables.map((t) => t.name), ['Scores', 'Pilots']);
      expect(result.tables.first.rows, [
        {'Pilot': 'Ann', 'Score': 41.5},
        {'Pilot': 'Bob', 'Score': 39},
      ]);
      expect(result.tables.first.rowCount, 2);
      expect(result.tables.first.rowCapExceeded, isFalse);
    },
  );

  test(
    'importGliderScore omits the tables key when all tables are requested',
    () async {
      final client = clientFor(
        (_) => body({
          'schema': 'gs-import/v1',
          'id': '019c0000-0000-7000-8000-000000000a02',
          'sourceDbFile': 'GliderScoreData.mdb',
          'tables': <Object?>[],
        }, 201),
      );

      final result = await client.importGliderScore('C:\\GliderScoreData.mdb');

      expect(jsonDecode(seen.body), {'path': r'C:\GliderScoreData.mdb'});
      expect(result.tables, isEmpty);
    },
  );

  test(
    'a 503 response is an ApiHttpError with the import_unavailable code',
    () async {
      final client = clientFor(
        (_) => body({
          'error': {
            'code': 'import_unavailable',
            'message': 'GliderScore import is unavailable on this machine',
          },
        }, 503),
      );

      await expectLater(
        client.importGliderScore('C:\\GliderScoreData.mdb'),
        throwsA(
          isA<ApiHttpError>()
              .having((e) => e.statusCode, 'status', 503)
              .having((e) => e.error?.code, 'code', 'import_unavailable'),
        ),
      );
    },
  );
}
