import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/auth/auth_session.dart';
import 'package:soar_score_contest/server/auth_callback_server.dart';

Future<int> _freePort() async {
  final socket = await ServerSocket.bind('localhost', 0);
  final port = socket.port;
  await socket.close();
  return port;
}

void main() {
  late AuthCallbackServer server;
  late int port;
  late HttpClient client;

  setUp(() async {
    port = await _freePort();
    server = AuthCallbackServer(port: port, appScheme: 'com.soarscore.contest');
    client = HttpClient();
    await server.start();
  });

  tearDown(() async {
    client.close(force: true);
    await server.stop();
  });

  Future<(HttpClientResponse, String)> get(
    String path, {
    String method = 'GET',
  }) async {
    final request = await client.openUrl(
      method,
      Uri.parse('http://localhost:$port$path'),
    );
    final response = await request.close();
    final body = await response
        .transform(const SystemEncoding().decoder)
        .join();
    return (response, body);
  }

  test('a successful callback says the window can be closed', () async {
    final (response, body) = await get('/callback?code=abc&state=xyz');

    expect(response.statusCode, 200);
    expect(response.headers.value('cache-control'), 'no-store');
    expect(response.headers.value('referrer-policy'), 'no-referrer');
    expect(body, contains('You are signed in'));
    expect(body, contains('close this browser window'));
  });

  test(
    'a successful callback forwards the code and state to the app',
    () async {
      final (_, body) = await get('/callback?code=abc%2F1&state=xyz');

      expect(
        body,
        contains(
          r'"com.soarscore.contest://callback?code=abc%2F1\u0026state=xyz"',
        ),
      );
      expect(
        body,
        contains(
          'href="com.soarscore.contest:&#47;&#47;callback?code=abc%2F1&amp;state=xyz"',
        ),
      );
    },
  );

  test('an Auth0 error is shown and forwarded to the app', () async {
    final (response, body) = await get(
      '/callback?error=access_denied&error_description=Nope%20%3Cb%3E',
    );

    expect(response.statusCode, 200);
    expect(body, contains('Sign-in was not completed'));
    expect(body, contains('Nope &lt;b&gt;'));
    expect(body, isNot(contains('Nope <b>')));
    expect(
      body,
      contains('com.soarscore.contest://callback?error=access_denied'),
    );
  });

  test(
    'a callback without code and state is refused and not forwarded',
    () async {
      final (response, body) = await get('/callback?code=abc');

      expect(response.statusCode, 400);
      expect(body, isNot(contains('com.soarscore.contest')));
    },
  );

  test('the logout page says the window can be closed', () async {
    final (response, body) = await get('/logout');

    expect(response.statusCode, 200);
    expect(body, contains('You are signed out'));
    expect(body, contains('"com.soarscore.contest://callback"'));
  });

  test('other paths and methods serve nothing', () async {
    expect((await get('/')).$1.statusCode, 404);
    expect((await get('/api/v1/contests')).$1.statusCode, 404);
    expect((await get('/callback', method: 'POST')).$1.statusCode, 405);
  });

  test('only the app scheme is ever a forward target', () async {
    final (_, body) = await get(
      '/callback?code=a&state=b&redirect=https://evil.example/',
    );

    expect(body, isNot(contains('evil.example')));
  });

  test('stop releases the port', () async {
    await server.stop();

    final other = AuthCallbackServer(port: port, appScheme: 'x');
    await other.start();
    await other.stop();
  });

  test('a busy port is reported as a sign-in problem', () async {
    final other = AuthCallbackServer(port: port, appScheme: 'x');

    await expectLater(other.start(), throwsA(isA<AuthException>()));
  });
}
