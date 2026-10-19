import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_contest/auth/identity_provider_check.dart';

void main() {
  group('IdentityProviderCheck', () {
    test('publishes available on a 200 response', () async {
      final check = IdentityProviderCheck(
        tenantDomain: 'tenant.example',
        client: MockClient((request) async {
          expect(
            request.url,
            Uri.https('tenant.example', '/.well-known/openid-configuration'),
          );
          return http.Response(
            '{}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(check.dispose);

      expect(check.status, IdentityProviderStatus.checking);
      await check.probe();

      expect(check.status, IdentityProviderStatus.available);
      expect(check.lastError, isNull);
    });

    test('publishes unavailable with the status on a 500 response', () async {
      final check = IdentityProviderCheck(
        tenantDomain: 'tenant.example',
        client: MockClient((request) async => http.Response('oops', 500)),
      );
      addTearDown(check.dispose);

      await check.probe();

      expect(check.status, IdentityProviderStatus.unavailable);
      expect(check.lastError, 'HTTP 500');
    });

    test('publishes unavailable with a network reason when the client '
        'throws', () async {
      final check = IdentityProviderCheck(
        tenantDomain: 'tenant.example',
        client: MockClient((request) async {
          throw Exception('boom');
        }),
      );
      addTearDown(check.dispose);

      await check.probe();

      expect(check.status, IdentityProviderStatus.unavailable);
      expect(check.lastError, 'No network connection');
    });

    test('publishes unavailable with a timeout reason when the probe times '
        'out', () async {
      final check = IdentityProviderCheck(
        tenantDomain: 'tenant.example',
        client: MockClient((request) async {
          await Future<void>.delayed(const Duration(seconds: 30));
          return http.Response('{}', 200);
        }),
        timeout: const Duration(milliseconds: 10),
      );
      addTearDown(check.dispose);

      await check.probe();

      expect(check.status, IdentityProviderStatus.unavailable);
      expect(check.lastError, 'Timed out');
    });

    test('a second probe while one is in flight issues no second request', () async {
      var requests = 0;
      late Completer<http.Response> completer;
      final check = IdentityProviderCheck(
        tenantDomain: 'tenant.example',
        client: MockClient((request) async {
          requests++;
          completer = Completer();
          return completer.future;
        }),
      );
      addTearDown(check.dispose);

      final probe = check.probe();
      check.probe();
      // Let the in-flight handler issue its request before asserting.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(requests, 1);

      completer.complete(http.Response('{}', 200));
      await probe;

      expect(requests, 1);
      expect(check.status, IdentityProviderStatus.available);
    });

    test('a late completion after dispose neither notifies nor changes '
        'state', () async {
      late Completer<http.Response> completer;
      final check = IdentityProviderCheck(
        tenantDomain: 'tenant.example',
        client: MockClient((request) async {
          completer = Completer();
          return completer.future;
        }),
      );

      final probe = check.probe();
      // Let the in-flight handler run before disposing.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(check.status, IdentityProviderStatus.checking);
      check.dispose();
      completer.complete(http.Response('{}', 200));
      await probe;
    });
  });
}
