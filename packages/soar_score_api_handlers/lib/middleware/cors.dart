import 'package:shelf/shelf.dart';

/// Lets a browser app served from one of [allowedOrigins] call the API.
///
/// Origins match exactly (scheme, host and port), for example
/// `http://127.0.0.1:8091`. A request from any other origin, or without an
/// `Origin` header, passes through untouched and gets no CORS headers, so the
/// browser refuses it. With an empty set the middleware does nothing.
///
/// A preflight (`OPTIONS` with `Access-Control-Request-Method`) from an allowed
/// origin is answered here with 204 and never reaches the auth layer, which
/// would reject it for lacking a token. The preflight allows whatever headers
/// it asks for, so `Authorization` and `Content-Type` work. Every response to
/// an allowed origin, errors included, carries `Access-Control-Allow-Origin`
/// and `Vary: Origin`. Credentials are allowed, for the self-scoring app's
/// guest session cookie; the origin is always the exact one, never `*`.
Middleware corsMiddleware(Set<String> allowedOrigins) {
  if (allowedOrigins.isEmpty) return (inner) => inner;
  return (inner) => (request) async {
    final origin = request.headers['origin'];
    if (origin == null || !allowedOrigins.contains(origin)) {
      return inner(request);
    }
    final isPreflight =
        request.method == 'OPTIONS' &&
        request.headers.containsKey('access-control-request-method');
    if (isPreflight) {
      final requested = request.headers['access-control-request-headers'];
      return Response(
        204,
        headers: {
          'access-control-allow-origin': origin,
          'access-control-allow-methods': 'GET, POST, PUT, PATCH, DELETE',
          'access-control-allow-headers': ?requested,
          'access-control-allow-credentials': 'true',
          'access-control-max-age': '600',
          'vary': 'Origin',
        },
      );
    }
    final response = await inner(request);
    return response.change(
      headers: {
        'access-control-allow-origin': origin,
        'access-control-allow-credentials': 'true',
        'access-control-expose-headers': 'x-request-id',
        'vary': 'Origin',
      },
    );
  };
}
