import 'package:shelf/shelf.dart';

/// Headers that keep the API out of search indexes and stop browsers from
/// guessing content types.
///
/// - `X-Content-Type-Options: nosniff` and `X-Robots-Tag: noindex, nofollow`
///   on every response.
/// - `Cache-Control: no-store` on `/api/v1` responses (they are signed-in
///   data), unless a handler already chose its own. The `/public` reads
///   keep the cache headers their handlers set.
Middleware securityHeadersMiddleware() =>
    (inner) => (request) async {
      final response = await inner(request);
      final authenticated = request.url.path.startsWith('api/v1');
      return response.change(
        headers: {
          'x-content-type-options': 'nosniff',
          'x-robots-tag': 'noindex, nofollow',
          if (authenticated && !response.headers.containsKey('cache-control'))
            'cache-control': 'no-store',
        },
      );
    };

/// `GET /robots.txt`: the API is not for crawlers.
Response robotsTxtHandler(Request request) => Response.ok(
  'User-agent: *\nDisallow: /\n',
  headers: {'content-type': 'text/plain; charset=utf-8'},
);
