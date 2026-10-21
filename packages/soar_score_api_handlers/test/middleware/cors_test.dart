import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';
import 'package:test/test.dart';

void main() {
  const origin = 'http://127.0.0.1:8091';
  var innerCalls = 0;

  Handler build(Set<String> allowed) {
    innerCalls = 0;
    return const Pipeline().addMiddleware(corsMiddleware(allowed)).addHandler((
      request,
    ) {
      innerCalls++;
      return request.headers.containsKey('authorization')
          ? Response.ok('ok')
          : Response.unauthorized('no token');
    });
  }

  Request request(String method, {String? from, Map<String, String>? extra}) =>
      Request(
        method,
        Uri.parse('http://127.0.0.1:8080/api/v1/contests'),
        headers: {'origin': ?from, ...?extra},
      );

  test(
    'answers a preflight from an allowed origin without calling inner',
    () async {
      final response = await build({origin})(
        request(
          'OPTIONS',
          from: origin,
          extra: {
            'access-control-request-method': 'GET',
            'access-control-request-headers': 'authorization,content-type',
          },
        ),
      );

      expect(response.statusCode, 204);
      expect(response.headers['access-control-allow-origin'], origin);
      expect(
        response.headers['access-control-allow-headers'],
        'authorization,content-type',
      );
      expect(
        response.headers['access-control-allow-methods'],
        contains('PATCH'),
      );
      expect(response.headers['vary'], 'Origin');
      expect(innerCalls, 0);
    },
  );

  test('adds the origin to normal and error responses', () async {
    final handler = build({origin});

    final ok = await handler(
      request('GET', from: origin, extra: {'authorization': 'Bearer t'}),
    );
    final unauthorized = await handler(request('GET', from: origin));

    expect(ok.statusCode, 200);
    expect(ok.headers['access-control-allow-origin'], origin);
    expect(unauthorized.statusCode, 401);
    expect(unauthorized.headers['access-control-allow-origin'], origin);
  });

  test('gives other origins no CORS headers', () async {
    final handler = build({origin});

    final other = await handler(request('GET', from: 'http://evil.example'));
    final none = await handler(request('GET'));
    final preflight = await handler(
      request(
        'OPTIONS',
        from: 'http://evil.example',
        extra: {'access-control-request-method': 'GET'},
      ),
    );

    for (final response in [other, none, preflight]) {
      expect(response.headers, isNot(contains('access-control-allow-origin')));
    }
    expect(innerCalls, 3);
  });

  test('matches origins exactly', () async {
    final response = await build({origin})(
      request('GET', from: 'http://127.0.0.1:8092'),
    );

    expect(response.headers, isNot(contains('access-control-allow-origin')));
  });

  test('does nothing when no origins are allowed', () async {
    final response = await build({})(request('GET', from: origin));

    expect(response.headers, isNot(contains('access-control-allow-origin')));
  });
}
