import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_server/handler.dart';
import 'package:test/test.dart';

void main() {
  late Handler handler;

  setUp(() {
    handler = createServerHandler();
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
      expect(await readJson(response), {
        'name': 'soar_score_server',
        'displayName': 'Soar Score API Server',
        'version': '0.1.0',
      });
    });
  });

  group('/api/v1', () {
    test('GET /api/v1/meta returns the identity placeholder', () async {
      final response = await get('/api/v1/meta');

      expect(response.statusCode, 200);
      expect(await readJson(response), {
        'name': 'soar_score_server',
        'displayName': 'Soar Score API Server',
        'version': '0.1.0',
      });
    });

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
}
