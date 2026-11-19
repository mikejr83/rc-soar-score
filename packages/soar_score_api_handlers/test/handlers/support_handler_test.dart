import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:test/test.dart';

import '../stubs/memory_throttle_store.dart';

class _FakeVerifier implements SupportChallengeVerifier {
  _FakeVerifier({this.result});

  /// null passes; otherwise thrown.
  final Object? result;
  int calls = 0;

  @override
  Future<void> verify(String token, {required String address}) async {
    calls++;
    if (result != null) throw result!;
  }
}

Map<String, Object?> _valid([Map<String, Object?> overrides = const {}]) => {
  'name': 'A Pilot',
  'email': 'pilot@example.test',
  'userType': 'Pilot',
  'requestType': 'Online Score Entry',
  'message': 'I cannot enter my score.',
  'captchaToken': 'fake-token',
  ...overrides,
};

Request _post(
  Object? body, {
  String address = '198.51.100.7',
  Map<String, String>? extra,
}) => Request(
  'POST',
  Uri.parse('http://localhost/public/support'),
  body: body is String ? body : jsonEncode(body),
  headers: {
    'content-type': 'application/json',
    'fly-client-ip': address,
    ...?extra,
  },
);

void main() {
  late DateTime now;
  late MemoryThrottleStore store;
  late List<SupportSubmission> sent;
  late _FakeVerifier verifier;
  late SupportDelivery sendResult;

  SupportAttemptQuota quotaFor(MemoryThrottleStore s) => SupportAttemptQuota(
    store: s,
    keySecret: 'k' * 32,
    clock: () => now,
  );

  Handler handler({
    SupportAttemptQuota? quota,
    SupportChallengeVerifier? challenge,
  }) => const Pipeline().addMiddleware(errorMappingMiddleware()).addHandler(
    buildSupportHandler(
      quota: quota ?? quotaFor(store),
      verifier: challenge ?? verifier,
      send: (s) async {
        sent.add(s);
        return sendResult;
      },
    ),
  );

  setUp(() {
    now = DateTime.utc(2026, 1, 1, 12);
    store = MemoryThrottleStore(clock: () => now);
    sent = [];
    verifier = _FakeVerifier();
    sendResult = SupportDelivery.accepted;
  });

  test('a valid request is sent and answers accepted', () async {
    final response = await handler()(_post(_valid()));
    expect(response.statusCode, 200);
    expect(jsonDecode(await response.readAsString()), {'accepted': true});
    expect(sent.single.email, 'pilot@example.test');
    expect(sent.single.userType, 'Pilot');
    expect(verifier.calls, 1);
  });

  test('a blank optional user type is accepted', () async {
    final response = await handler()(_post(_valid({'userType': ''})));
    expect(response.statusCode, 200);
    expect(sent.single.userType, '');
  });

  test('malformed JSON is 400 and sends nothing', () async {
    final response = await handler()(_post('{nope'));
    expect(response.statusCode, 400);
    expect(sent, isEmpty);
    expect(verifier.calls, 0);
  });

  test('an unknown field such as a destination is refused', () async {
    final response = await handler()(
      _post(_valid({'to': 'someone@example.test'})),
    );
    expect(response.statusCode, 400);
    expect(sent, isEmpty);
  });

  test('an invalid email, including a Unicode domain, is refused', () async {
    for (final email in [
      'josé@example.com',
      'pilot@bücher.example',
      'a,b@example.com',
      'pilot@example.com\n',
    ]) {
      final response = await handler()(_post(_valid({'email': email})));
      expect(response.statusCode, 400, reason: email);
    }
    expect(sent, isEmpty);
  });

  test('an ASCII-encoded domain and padded address are accepted', () async {
    final response = await handler()(
      _post(_valid({'email': '  pilot+x@xn--bcher-kva.example  '})),
    );
    expect(response.statusCode, 200);
    expect(sent.single.email, 'pilot+x@xn--bcher-kva.example');
  });

  test('a message of 2,000 units is accepted and 2,001 is refused', () async {
    expect(
      (await handler()(_post(_valid({'message': 'x' * 2000})))).statusCode,
      200,
    );
    expect(
      (await handler()(_post(_valid({'message': 'x' * 2001})))).statusCode,
      400,
    );
  });

  test('an unknown request type is refused', () async {
    final response = await handler()(
      _post(_valid({'requestType': 'Sales'})),
    );
    expect(response.statusCode, 400);
  });

  test('an oversized body is 413 before any upstream call', () async {
    final response = await handler()(_post(_valid({'message': 'x' * 40000})));
    expect(response.statusCode, 413);
    expect(sent, isEmpty);
    expect(verifier.calls, 0);
  });

  test('a rejected challenge is captcha_invalid and sends nothing', () async {
    verifier = _FakeVerifier(result: const SupportChallengeRejected());
    final response = await handler()(_post(_valid()));
    expect(response.statusCode, 400);
    expect(jsonDecode(await response.readAsString())['error']['code'], 'captcha_invalid');
    expect(sent, isEmpty);
  });

  test('a verification outage is 503 and sends nothing', () async {
    verifier = _FakeVerifier(result: StateError('upstream down'));
    final response = await handler()(_post(_valid()));
    expect(response.statusCode, 503);
    expect(sent, isEmpty);
  });

  test('a store outage is 503 before verification or sending', () async {
    store.failing = true;
    final response = await handler()(_post(_valid()));
    expect(response.statusCode, 503);
    expect(verifier.calls, 0);
    expect(sent, isEmpty);
  });

  test('a rejected provider send is 503 support_unavailable', () async {
    sendResult = SupportDelivery.rejected;
    final response = await handler()(_post(_valid()));
    expect(response.statusCode, 503);
    expect(jsonDecode(await response.readAsString())['error']['code'], 'support_unavailable');
  });

  test('an unconfirmed send is 503 delivery_unconfirmed', () async {
    sendResult = SupportDelivery.unconfirmed;
    final response = await handler()(_post(_valid()));
    expect(response.statusCode, 503);
    expect(jsonDecode(await response.readAsString())['error']['code'], 'delivery_unconfirmed');
  });

  test('five attempts pass, the sixth is 429, another caller passes, and the first passes after ten minutes', () async {
    final first = handler();
    for (var i = 0; i < 5; i++) {
      final response = await first(_post(_valid()));
      expect(response.statusCode, 200, reason: 'attempt ${i + 1}');
    }
    final limited = await first(_post(_valid()));
    expect(limited.statusCode, 429);
    expect(limited.headers['retry-after'], isNotNull);
    expect(sent.length, 5);

    // Another caller, and the same caller through a second instance sharing
    // the store.
    expect(
      (await handler()(_post(_valid(), address: '203.0.113.9'))).statusCode,
      200,
    );
    expect((await handler()(_post(_valid()))).statusCode, 429);

    now = now.add(const Duration(minutes: 10));
    expect((await first(_post(_valid()))).statusCode, 200);
  });

  test('a request refused by the quota never reads the body', () async {
    store.failing = true;
    final response = await handler()(_post('not json at all'));
    expect(response.statusCode, 503);
  });

  test('the handler is a plain shelf handler', () {
    expect(handler(), isA<Handler>());
  });
}
