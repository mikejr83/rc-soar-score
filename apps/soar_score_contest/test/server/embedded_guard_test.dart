import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/server/embedded_guard.dart';
import 'package:soar_score_contest/server/embedded_server.dart';

void main() {
  late Directory tempDir;
  late EmbeddedServer server;
  late HttpClient http;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('soar_score_guard_test');
    server = await startEmbeddedServer(
      '${tempDir.path}${Platform.pathSeparator}soar_score.db',
    );
    http = HttpClient();
  });

  tearDown(() async {
    http.close(force: true);
    await server.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// Sends a raw request so each test controls the headers the app's own
  /// client would set.
  Future<int> send(
    String method,
    String path, {
    String? token,
    String? host,
    String? origin,
    String? contentType,
    String? body,
  }) async {
    final request = await http.openUrl(method, server.baseUrl.resolve(path));
    if (host != null) {
      request.headers.host = host;
      request.headers.port = server.port;
    }
    if (token != null) request.headers.set('authorization', 'Bearer $token');
    if (origin != null) request.headers.set('origin', origin);
    if (contentType != null) request.headers.set('content-type', contentType);
    if (body != null) {
      final bytes = utf8.encode(body);
      request.contentLength = bytes.length;
      request.add(bytes);
    }
    final response = await request.close();
    await response.drain<void>();
    return response.statusCode;
  }

  test('binds to the IPv4 loopback address', () {
    expect(server.baseUrl.host, '127.0.0.1');
    expect(server.secret.length, greaterThanOrEqualTo(43));
  });

  test('refuses a request with no token', () async {
    expect(await send('GET', '/api/v1/contests'), 401);
  });

  test('refuses a request with the wrong token', () async {
    expect(await send('GET', '/api/v1/contests', token: 'nope'), 401);
  });

  test('keeps /health open without a token', () async {
    expect(await send('GET', '/health'), 200);
  });

  test('accepts the launch secret', () async {
    expect(await send('GET', '/api/v1/contests', token: server.secret), 200);
  });

  test('refuses a foreign Host even with the secret', () async {
    expect(
      await send(
        'GET',
        '/api/v1/contests',
        token: server.secret,
        host: 'evil.example',
      ),
      403,
    );
    expect(await send('GET', '/health', host: 'evil.example'), 403);
  });

  test('accepts localhost as the Host', () async {
    expect(
      await send(
        'GET',
        '/api/v1/contests',
        token: server.secret,
        host: 'localhost',
      ),
      200,
    );
  });

  test('refuses any request that carries an Origin', () async {
    expect(
      await send(
        'GET',
        '/api/v1/contests',
        token: server.secret,
        origin: 'https://evil.example',
      ),
      403,
    );
    expect(await send('GET', '/health', origin: 'null'), 403);
  });

  test('refuses a write that is not application/json', () async {
    expect(
      await send(
        'POST',
        '/api/v1/roles',
        token: server.secret,
        contentType: 'text/plain',
        body: '{"name":"x"}',
      ),
      415,
    );
  });

  test('the app client round-trips with the secret', () async {
    final client = ApiClient(
      baseUrl: server.baseUrl,
      tokenProvider: () async => server.secret,
    );
    try {
      expect(await client.contests(), isNotNull);
    } finally {
      client.close();
    }
  });

  test('constantTimeEquals compares whole strings', () {
    expect(constantTimeEquals('abc', 'abc'), isTrue);
    expect(constantTimeEquals('abc', 'abd'), isFalse);
    expect(constantTimeEquals('abc', 'abcd'), isFalse);
    expect(constantTimeEquals('', ''), isTrue);
  });
}
