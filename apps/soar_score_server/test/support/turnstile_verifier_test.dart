import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_server/support/turnstile_verifier.dart';
import 'package:test/test.dart';

const _host = 'soar.example.test';

void main() {
  late List<http.Request> requests;

  TurnstileVerifier verifier({
    required http.Response Function(http.Request) respond,
    Duration deadline = siteverifyDeadline,
  }) => TurnstileVerifier(
    secret: 'turnstile-secret',
    allowedHostnames: {_host},
    client: MockClient((request) async {
      requests.add(request);
      return respond(request);
    }),
    deadline: deadline,
  );

  http.Response siteverify(Map<String, Object?> body) =>
      http.Response(jsonEncode(body), 200);

  setUp(() => requests = []);

  test('a successful token for this action and hostname is accepted', () async {
    await verifier(
      respond: (_) => siteverify({
        'success': true,
        'action': supportTurnstileAction,
        'hostname': _host,
      }),
    ).verify('token', address: '203.0.113.7');
  });

  test(
    'the request posts the secret and token, never the visitor address',
    () async {
      await verifier(
        respond: (_) => siteverify({
          'success': true,
          'action': supportTurnstileAction,
          'hostname': _host,
        }),
      ).verify('token', address: '203.0.113.7');

      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.url, siteverifyUri);
      expect(request.bodyFields, {
        'secret': 'turnstile-secret',
        'response': 'token',
      });
      expect(request.body, isNot(contains('203.0.113.7')));
    },
  );

  test('a success for another action is rejected', () async {
    expect(
      verifier(
        respond: (_) =>
            siteverify({'success': true, 'action': 'login', 'hostname': _host}),
      ).verify('token', address: 'x'),
      throwsA(isA<SupportChallengeRejected>()),
    );
  });

  test('a success for an unlisted hostname is rejected', () async {
    expect(
      verifier(
        respond: (_) => siteverify({
          'success': true,
          'action': supportTurnstileAction,
          'hostname': 'elsewhere.example.test',
        }),
      ).verify('token', address: 'x'),
      throwsA(isA<SupportChallengeRejected>()),
    );
  });

  test('token errors are rejections the visitor can retry', () async {
    for (final code in ['invalid-input-response', 'timeout-or-duplicate']) {
      await expectLater(
        verifier(
          respond: (_) => siteverify({
            'success': false,
            'error-codes': [code],
          }),
        ).verify('token', address: 'x'),
        throwsA(isA<SupportChallengeRejected>()),
        reason: code,
      );
    }
  });

  test('a configuration error is an outage, not a rejection', () async {
    await expectLater(
      verifier(
        respond: (_) => siteverify({
          'success': false,
          'error-codes': ['invalid-input-secret'],
        }),
      ).verify('token', address: 'x'),
      throwsA(allOf(isA<StateError>(), isNot(isA<SupportChallengeRejected>()))),
    );
  });

  test('an upstream HTTP failure is an outage', () async {
    await expectLater(
      verifier(respond: (_) => http.Response('down', 503))
          .verify('token', address: 'x'),
      throwsA(allOf(isA<StateError>(), isNot(isA<SupportChallengeRejected>()))),
    );
  });

  test('an unreadable body is an outage', () async {
    await expectLater(
      verifier(respond: (_) => http.Response('<html>', 200))
          .verify('token', address: 'x'),
      throwsA(isA<FormatException>()),
    );
  });

  test('a slow Siteverify times out instead of waiting', () async {
    final slow = TurnstileVerifier(
      secret: 'turnstile-secret',
      allowedHostnames: {_host},
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(seconds: 2));
        return siteverify({'success': true});
      }),
      deadline: const Duration(milliseconds: 50),
    );
    await expectLater(
      slow.verify('token', address: 'x'),
      throwsA(isA<TimeoutException>()),
    );
  });
}
