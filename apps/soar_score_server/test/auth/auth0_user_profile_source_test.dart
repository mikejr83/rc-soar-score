import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_server/auth/auth0_user_profile_source.dart';
import 'package:test/test.dart';

void main() {
  Auth0UserProfileSource sourceFor(
    Future<http.Response> Function(http.Request) respond,
  ) => Auth0UserProfileSource(
    domain: 'tenant.us.auth0.com',
    client: MockClient(respond),
    timeout: const Duration(milliseconds: 200),
  );

  test('sends the token to /userinfo and reads the profile', () async {
    late http.Request seen;
    final source = sourceFor((request) async {
      seen = request;
      return http.Response(
        jsonEncode({
          'sub': 'auth0|abc',
          'given_name': 'Ada',
          'family_name': 'Lovelace',
          'name': 'Ada Lovelace',
          'email': 'ada@example.com',
          'email_verified': true,
        }),
        200,
      );
    });

    final profile = await source.fetch('the-token');

    expect(seen.url, Uri.parse('https://tenant.us.auth0.com/userinfo'));
    expect(seen.headers['authorization'], 'Bearer the-token');
    expect(profile.givenName, 'Ada');
    expect(profile.familyName, 'Lovelace');
    expect(profile.name, 'Ada Lovelace');
    expect(profile.email, 'ada@example.com');
    expect(profile.emailVerified, isTrue);
  });

  test('treats missing fields as absent', () async {
    final source = sourceFor(
      (_) async => http.Response(jsonEncode({'sub': 'auth0|abc'}), 200),
    );

    final profile = await source.fetch('t');

    expect(profile.givenName, isNull);
    expect(profile.email, isNull);
    expect(profile.emailVerified, isFalse);
  });

  test('reports a refusal as unavailable', () async {
    final source = sourceFor((_) async => http.Response('nope', 401));

    await expectLater(
      source.fetch('t'),
      throwsA(isA<UserProfileUnavailableException>()),
    );
  });

  test('reports a body that is not a JSON object as unavailable', () async {
    for (final body in ['<html>', '[1]']) {
      final source = sourceFor((_) async => http.Response(body, 200));

      await expectLater(
        source.fetch('t'),
        throwsA(isA<UserProfileUnavailableException>()),
        reason: body,
      );
    }
  });

  test('reports a network failure or timeout as unavailable', () async {
    final failing = sourceFor((_) async => throw http.ClientException('down'));
    final slow = sourceFor((_) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      return http.Response('{}', 200);
    });

    await expectLater(
      failing.fetch('t'),
      throwsA(isA<UserProfileUnavailableException>()),
    );
    await expectLater(
      slow.fetch('t'),
      throwsA(isA<UserProfileUnavailableException>()),
    );
  });
}
