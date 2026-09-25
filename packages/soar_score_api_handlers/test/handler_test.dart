import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:test/test.dart';

import 'stubs/stub_contest_repository.dart';
import 'stubs/stub_repository.dart';

/// The identity the extracted routing code is given in these tests. It
/// matches the payload shape the deployed `soar_score_server` served before
/// the handlers were extracted from it (ticket 003).
const testIdentity = HealthDto(
  name: 'soar_score_server',
  displayName: 'Soar Score API Server',
  version: '0.1.0',
);

void main() {
  late Handler handler;

  setUp(() {
    handler = buildApiHandler(
      name: testIdentity.name,
      displayName: testIdentity.displayName,
      version: testIdentity.version,
      repository: StubRepository(StubContestRepository()),
    );
  });

  Future<Response> get(String path) async {
    return handler(Request('GET', Uri.parse('http://localhost$path')));
  }

  Future<Map<String, Object?>> readJson(Response response) async {
    expect(response.headers['content-type'], contains('application/json'));
    return jsonDecode(await response.readAsString()) as Map<String, Object?>;
  }

  group('/health', () {
    test('returns 200 JSON with name, displayName and version', () async {
      final response = await get('/health');

      expect(response.statusCode, 200);
      expect(await readJson(response), testIdentity.toJson());
    });
  });

  group('/api/v1', () {
    test('GET /api/v1/ping returns ok', () async {
      final response = await get('/api/v1/ping');

      expect(response.statusCode, 200);
      expect(await readJson(response), {'status': 'ok'});
    });

    test('unknown routes return 404', () async {
      expect((await get('/api/v1/nope')).statusCode, 404);
      expect((await get('/nope')).statusCode, 404);
    });
  });

  group('auth middleware seam', () {
    final tokenHeader = 'Authorization';

    late Handler protectedHandler;

    setUp(() {
      protectedHandler = buildApiHandler(
        name: testIdentity.name,
        displayName: testIdentity.displayName,
        version: testIdentity.version,
        repository: StubRepository(StubContestRepository()),
        authMiddleware: (api) {
          return (Request request) {
            final token = request.headers[tokenHeader];
            if (token != 'test-token') {
              return Response(
                401,
                body: jsonEncode(<String, Object>{'error': 'unauthorized'}),
                headers: <String, Object>{
                  'content-type': 'application/json; charset=utf-8',
                },
              );
            }
            return api(request);
          };
        },
      );
    });

    Future<Response> getAuthed(String path, {String? token}) async {
      return protectedHandler(
        Request(
          'GET',
          Uri.parse('http://localhost$path'),
          headers: token == null ? null : <String, Object>{tokenHeader: token},
        ),
      );
    }

    test('rejects /api/v1 requests without a valid token', () async {
      expect((await getAuthed('/api/v1/meta')).statusCode, 401);
      expect((await getAuthed('/api/v1/ping')).statusCode, 401);
    });

    test('accepts /api/v1 requests with a valid token', () async {
      final response = await getAuthed('/api/v1/ping', token: 'test-token');

      expect(response.statusCode, 200);
      expect(jsonDecode(await response.readAsString()), {'status': 'ok'});
    });

    test(
      'leaves /health unauthenticated when a middleware is configured',
      () async {
        expect((await getAuthed('/health')).statusCode, 200);
      },
    );
  });
}
