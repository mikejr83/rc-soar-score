import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_contest/auth/identity_provider_check.dart';

import 'support/recording_http_client.dart';

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
        client: _AbortAwareClient(
          onRequest: () {},
          onAbort: () {},
        ),
        timeout: const Duration(milliseconds: 10),
      );
      addTearDown(check.dispose);

      await check.probe();

      expect(check.status, IdentityProviderStatus.unavailable);
      expect(check.lastError, 'Timed out');
    });

    test('aborts a timed-out request before allowing a retry', () async {
      var requests = 0;
      var aborted = 0;
      final check = IdentityProviderCheck(
        tenantDomain: 'tenant.example',
        client: _AbortAwareClient(
          onRequest: () => requests++,
          onAbort: () => aborted++,
        ),
        timeout: const Duration(milliseconds: 10),
      );
      addTearDown(check.dispose);

      await check.probe();
      expect(aborted, 1);
      expect(check.lastError, 'Timed out');

      await check.probe();
      expect(requests, 2);
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

    test('dispose closes the client the check created itself', () async {
      final recorder = <String>[];
      late IdentityProviderCheck check;
      http.runWithClient(
        () {
          // No client injected: the check builds its own via `http.Client()`,
          // which the zone override routes to the recording client.
          check = IdentityProviderCheck(tenantDomain: 'tenant.example');
        },
        () => RecordingHttpClient(recorder),
      );

      await check.probe();
      expect(recorder, contains('send'), reason: 'probe issued one request');

      check.dispose();
      expect(recorder, contains('close'),
          reason: 'dispose closed the owned client');
    });

    test('dispose leaves an injected client open for its owner to close', () async {
      final recorder = <String>[];
      final client = RecordingHttpClient(recorder);
      final check = IdentityProviderCheck(
        tenantDomain: 'tenant.example',
        client: client,
      );

      await check.probe();
      expect(recorder, contains('send'));

      check.dispose();
      expect(recorder, isNot(contains('close')),
          reason: 'an injected client stays open until its owner closes it');
      // The owner can still close it afterwards.
      client.close();
      expect(recorder, contains('close'));
    });
  });
}

class _AbortAwareClient extends http.BaseClient {
  _AbortAwareClient({required this.onRequest, required this.onAbort});

  final void Function() onRequest;
  final void Function() onAbort;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    onRequest();
    final abortable = request as http.AbortableRequest;
    abortable.abortTrigger!.then((_) => onAbort());
    await abortable.abortTrigger;
    throw http.RequestAbortedException(request.url);
  }
}
