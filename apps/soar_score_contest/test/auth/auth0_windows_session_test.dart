import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_contest/auth/auth0_windows_session.dart';
import 'package:soar_score_contest/auth/auth_callback_listener.dart';
import 'package:soar_score_contest/auth/auth_config.dart';
import 'package:soar_score_contest/auth/auth_session.dart';

const _key = 'auth0_credentials';

final _now = DateTime.utc(2026, 10, 13, 12);

String _stored({
  required DateTime expiresAt,
  String? refreshToken = 'refresh',
}) => jsonEncode(
  Credentials(
    idToken: 'id',
    accessToken: 'access',
    refreshToken: refreshToken,
    expiresAt: expiresAt,
    user: const UserProfile(
      sub: 'auth0|1',
      name: 'Pat Pilot',
      email: 'pat@example.com',
    ),
    tokenType: 'Bearer',
  ).toMap(),
);

Auth0WindowsSession _session() =>
    Auth0WindowsSession(Auth0Config.windows(), now: () => _now);

class _BusyListener implements AuthCallbackListener {
  int stops = 0;

  @override
  Future<void> start() async => throw const AuthException('port busy');

  @override
  Future<void> stop() async => stops++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sign-in stops with a message when the callback port is busy', () async {
    final listener = _BusyListener();
    final session = Auth0WindowsSession(
      Auth0Config.windows(),
      callbackListener: listener,
    );

    await expectLater(
      session.signIn(),
      throwsA(
        isA<AuthException>().having((e) => e.message, 'message', 'port busy'),
      ),
    );
    expect(session.isSignedIn, isFalse);
  });

  test('the redirect URLs point at the loopback listener', () {
    final config = Auth0Config.windows();

    expect(config.windowsRedirectUrl, 'http://localhost:47821/callback');
    expect(config.windowsLogoutReturnUrl, 'http://localhost:47821/logout');
    expect(config.windowsCallbackUrl, 'com.soarscore.contest://callback');
  });

  test('restores a stored session that has not expired', () async {
    FlutterSecureStorage.setMockInitialValues({
      _key: _stored(expiresAt: _now.add(const Duration(hours: 1))),
    });
    final session = _session();

    await session.restore();

    expect(session.isSignedIn, isTrue);
    expect(session.displayName, 'Pat Pilot');
    expect(await session.accessToken(), 'access');
  });

  test('drops an unreadable stored session', () async {
    FlutterSecureStorage.setMockInitialValues({_key: 'not json'});
    final session = _session();

    await session.restore();

    expect(session.isSignedIn, isFalse);
    expect(await const FlutterSecureStorage().read(key: _key), isNull);
  });

  group('renewal', () {
    late DateTime now;
    late List<http.Request> requests;
    late Future<http.Response> Function(http.Request) respond;

    Auth0WindowsSession session() => Auth0WindowsSession(
      Auth0Config.windows(),
      now: () => now,
      httpClient: MockClient((request) {
        requests.add(request);
        return respond(request);
      }),
    );

    http.Response tokens({
      String access = 'access-2',
      String? refresh = 'refresh-2',
      int expiresIn = 3600,
    }) => http.Response(
      jsonEncode({
        'access_token': access,
        'refresh_token': ?refresh,
        'expires_in': expiresIn,
        'scope': 'openid profile email offline_access',
        'token_type': 'Bearer',
      }),
      200,
    );

    Future<Auth0WindowsSession> signedInAndExpired() async {
      FlutterSecureStorage.setMockInitialValues({
        _key: _stored(expiresAt: _now.add(const Duration(minutes: 5))),
      });
      final s = session();
      await s.restore();
      now = _now.add(const Duration(minutes: 10));
      return s;
    }

    Future<Credentials> storedCredentials() async => Credentials.fromMap(
      jsonDecode((await const FlutterSecureStorage().read(key: _key))!)
          as Map<String, dynamic>,
    );

    setUp(() {
      now = _now;
      requests = [];
      respond = (_) async => tokens();
    });

    test('exchanges the refresh token when the access token expired', () async {
      final s = await signedInAndExpired();

      expect(await s.accessToken(), 'access-2');

      expect(requests, hasLength(1));
      expect(
        requests.single.url,
        Uri.parse('https://${Auth0Config.defaultDomain}/oauth/token'),
      );
      expect(requests.single.bodyFields, {
        'grant_type': 'refresh_token',
        'client_id': Auth0Config.defaultWindowsClientId,
        'refresh_token': 'refresh',
      });
      expect(s.isSignedIn, isTrue);
      expect(s.displayName, 'Pat Pilot');
    });

    test('does not call Auth0 while the access token is valid', () async {
      FlutterSecureStorage.setMockInitialValues({
        _key: _stored(expiresAt: _now.add(const Duration(hours: 1))),
      });
      final s = session();
      await s.restore();

      expect(await s.accessToken(), 'access');
      expect(requests, isEmpty);
    });

    test('stores the rotated refresh token', () async {
      final s = await signedInAndExpired();

      await s.accessToken();

      final stored = await storedCredentials();
      expect(stored.refreshToken, 'refresh-2');
      expect(stored.accessToken, 'access-2');
      expect(stored.expiresAt, now.add(const Duration(hours: 1)));
      expect(stored.user.name, 'Pat Pilot');
    });

    test('keeps the old refresh token when Auth0 sends none', () async {
      respond = (_) async => tokens(refresh: null);
      final s = await signedInAndExpired();

      await s.accessToken();

      expect((await storedCredentials()).refreshToken, 'refresh');
    });

    test('uses the new refresh token on the next renewal', () async {
      final s = await signedInAndExpired();
      await s.accessToken();

      now = now.add(const Duration(hours: 2));
      respond = (_) async => tokens(access: 'access-3', refresh: 'refresh-3');

      expect(await s.accessToken(), 'access-3');
      expect(requests.last.bodyFields['refresh_token'], 'refresh-2');
    });

    test('concurrent requests share one exchange', () async {
      final s = await signedInAndExpired();

      final tokens = await Future.wait([
        s.accessToken(),
        s.accessToken(),
        s.accessToken(),
      ]);

      expect(tokens, ['access-2', 'access-2', 'access-2']);
      expect(requests, hasLength(1));
    });

    test(
      'renews a stored session that expired while the app was closed',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          _key: _stored(expiresAt: _now.subtract(const Duration(hours: 2))),
        });
        final s = session();

        await s.restore();

        expect(s.isSignedIn, isTrue);
        expect(await s.accessToken(), 'access-2');
      },
    );

    test('ends the session when Auth0 refuses the refresh token', () async {
      respond = (_) async =>
          http.Response(jsonEncode({'error': 'invalid_grant'}), 403);
      final s = await signedInAndExpired();
      var notified = 0;
      s.addListener(() => notified++);

      expect(await s.accessToken(), isNull);

      expect(s.isSignedIn, isFalse);
      expect(s.endedReason, isNotNull);
      expect(notified, 1);
      expect(await const FlutterSecureStorage().read(key: _key), isNull);
    });

    test('drops a restored session whose refresh token is refused', () async {
      respond = (_) async => http.Response('{}', 403);
      FlutterSecureStorage.setMockInitialValues({
        _key: _stored(expiresAt: _now.subtract(const Duration(hours: 2))),
      });
      final s = session();

      await s.restore();

      expect(s.isSignedIn, isFalse);
      expect(s.endedReason, isNotNull);
      expect(await const FlutterSecureStorage().read(key: _key), isNull);
    });

    test('ends an expired session that has no refresh token', () async {
      FlutterSecureStorage.setMockInitialValues({
        _key: _stored(
          expiresAt: _now.subtract(const Duration(minutes: 1)),
          refreshToken: null,
        ),
      });
      final s = session();

      await s.restore();

      expect(s.isSignedIn, isFalse);
      expect(s.endedReason, isNotNull);
      expect(requests, isEmpty);
    });

    for (final failure
        in <String, Future<http.Response> Function(http.Request)>{
          'the network is down': (_) async =>
              throw http.ClientException('offline'),
          'Auth0 has a server error': (_) async => http.Response('oops', 503),
          'Auth0 rate-limits the request': (_) async =>
              http.Response('{}', 429),
          'the answer is not usable': (_) async => http.Response('<html>', 200),
        }.entries) {
      test('keeps the session when ${failure.key}', () async {
        respond = failure.value;
        final s = await signedInAndExpired();

        expect(await s.accessToken(), isNull);

        expect(s.isSignedIn, isTrue);
        expect(s.endedReason, isNull);
        expect(
          (await storedCredentials()).refreshToken,
          'refresh',
          reason: 'the stored session is untouched',
        );
      });
    }

    test('retries after a failure, but not at once', () async {
      respond = (_) async => throw http.ClientException('offline');
      final s = await signedInAndExpired();
      await s.accessToken();

      await s.accessToken();
      expect(requests, hasLength(1), reason: 'too soon to retry');

      now = now.add(const Duration(seconds: 20));
      respond = (_) async => tokens();

      expect(await s.accessToken(), 'access-2');
      expect(requests, hasLength(2));
    });

    test('a restored session survives being offline at start', () async {
      respond = (_) async => throw http.ClientException('offline');
      FlutterSecureStorage.setMockInitialValues({
        _key: _stored(expiresAt: _now.subtract(const Duration(hours: 2))),
      });
      final s = session();

      await s.restore();

      expect(s.isSignedIn, isTrue);
      now = now.add(const Duration(seconds: 20));
      respond = (_) async => tokens();
      expect(await s.accessToken(), 'access-2');
    });
  });
}
