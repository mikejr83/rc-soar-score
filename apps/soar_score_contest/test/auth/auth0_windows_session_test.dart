import 'dart:convert';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/auth/auth0_windows_session.dart';
import 'package:soar_score_contest/auth/auth_config.dart';

const _key = 'auth0_credentials';

final _now = DateTime.utc(2026, 10, 13, 12);

String _stored({required DateTime expiresAt}) => jsonEncode(
  Credentials(
    idToken: 'id',
    accessToken: 'access',
    refreshToken: 'refresh',
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('drops a stored session that has expired', () async {
    FlutterSecureStorage.setMockInitialValues({
      _key: _stored(expiresAt: _now.subtract(const Duration(minutes: 1))),
    });
    final session = _session();

    await session.restore();

    expect(session.isSignedIn, isFalse);
    expect(await const FlutterSecureStorage().read(key: _key), isNull);
  });

  test('drops an unreadable stored session', () async {
    FlutterSecureStorage.setMockInitialValues({_key: 'not json'});
    final session = _session();

    await session.restore();

    expect(session.isSignedIn, isFalse);
    expect(await const FlutterSecureStorage().read(key: _key), isNull);
  });

  test('ends the session when the access token has expired', () async {
    var now = _now;
    FlutterSecureStorage.setMockInitialValues({
      _key: _stored(expiresAt: _now.add(const Duration(minutes: 5))),
    });
    final session = Auth0WindowsSession(Auth0Config.windows(), now: () => now);
    await session.restore();
    var notified = 0;
    session.addListener(() => notified++);

    now = _now.add(const Duration(minutes: 10));

    expect(await session.accessToken(), isNull);
    expect(session.isSignedIn, isFalse);
    expect(notified, 1);
  });
}
