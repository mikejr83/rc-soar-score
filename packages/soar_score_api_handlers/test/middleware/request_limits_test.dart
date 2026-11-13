import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

import '../handlers/handler_test_support.dart';
import '../handlers/matrix_test_support.dart';

final _owner = Id.parse('019c0000-0000-7000-8000-000000000001');

void main() {
  group('RequestRateLimiter', () {
    var now = DateTime.utc(2026, 11, 12, 12);
    setUp(() => now = DateTime.utc(2026, 11, 12, 12));
    RequestRateLimiter make({int max = 2, int maxKeys = 100}) =>
        RequestRateLimiter(
          maxRequests: max,
          window: const Duration(minutes: 1),
          maxKeys: maxKeys,
          clock: () => now,
        );

    test('refuses past the budget until the window ends', () {
      final limiter = make();
      limiter.check('a');
      limiter.check('a');
      limiter.check('b');
      final error = _refusal(() => limiter.check('a'));
      expect(error.retryAfter, const Duration(minutes: 1));
      now = now.add(const Duration(seconds: 61));
      limiter.check('a');
    });

    test('remembers a bounded number of keys', () {
      final limiter = make(max: 1, maxKeys: 2);
      for (final key in ['a', 'b', 'c']) {
        limiter.check(key);
      }
      limiter.check('a');
    });
  });

  group('request body size', () {
    late HandlerHarness api;
    setUp(() => api = HandlerHarness(_owner));

    Future<Response> post(Stream<List<int>> body, {int? length}) async =>
        api.handler(
          Request(
            'POST',
            Uri.parse('http://localhost/api/v1/contests'),
            body: body,
            headers: {if (length != null) 'content-length': '$length'},
          ),
        );

    test('a declared length over the limit is a 413', () async {
      final response = await post(
        Stream.value(utf8.encode('{}')),
        length: defaultMaxBodyBytes + 1,
      );
      expect(response.statusCode, 413);
      expect((await api.errorOf(response))['code'], 'payload_too_large');
    });

    test('a body without a length stops being read at the limit', () async {
      var chunks = 0;
      final stream = () async* {
        while (true) {
          chunks++;
          yield List.filled(64 * 1024, 0x20);
        }
      }();
      final response = await post(stream);
      expect(response.statusCode, 413);
      expect(chunks, lessThan(40));
    });

    test('an oversized body is refused before it is parsed', () async {
      final body = '{"x":"${'a' * (defaultMaxBodyBytes + 10)}"';
      final response = await post(Stream.value(utf8.encode(body)));
      expect(response.statusCode, 413);
    });

    test('a small bad body is still a 400', () async {
      final response = await post(Stream.value(utf8.encode('nope')));
      expect(response.statusCode, 400);
    });

    test('the sync exchange takes more than an ordinary route', () async {
      final padding = 'a' * (defaultMaxBodyBytes * 2);
      final response = await api.send(
        'POST',
        '/sync/exchange',
        body: {'padding': padding},
      );
      // Past the byte check (not 413): the body is then refused as invalid.
      expect(response.statusCode, 400);
    });

    test('an exchange over the sync limit is a 413', () async {
      final response = await api.handler(
        Request(
          'POST',
          Uri.parse('http://localhost/api/v1/sync/exchange'),
          body: Stream.value(utf8.encode('{}')),
          headers: {'content-length': '${syncExchangeMaxBodyBytes + 1}'},
        ),
      );
      expect(response.statusCode, 413);
    });
  });

  group('expensive routes', () {
    test('recalculation is limited per account', () async {
      final api = HandlerHarness(_owner);
      await drawnContest(api);
      final path = '/contests/$matrixTestContestId/results/recalculation';
      for (var i = 0; i < 10; i++) {
        expect((await api.send('POST', path)).statusCode, 200);
      }
      final refused = await api.send('POST', path);
      expect(refused.statusCode, 429);
      expect(refused.headers['retry-after'], isNotNull);
      expect((await api.errorOf(refused))['code'], 'rate_limited');
    });
  });
}

TooManyRequestsError _refusal(void Function() f) {
  try {
    f();
  } on TooManyRequestsError catch (e) {
    return e;
  }
  fail('expected a TooManyRequestsError');
}
