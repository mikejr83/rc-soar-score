import 'dart:convert';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:soar_score_api_handlers/soar_score_api_handlers.dart';

/// Makes a random secret of [bytes] bytes, base64url encoded, for the
/// embedded server's per-launch bearer token.
String generateEmbeddedSecret({int bytes = 32}) {
  final random = Random.secure();
  return base64Url
      .encode(List<int>.generate(bytes, (_) => random.nextInt(256)))
      .replaceAll('=', '');
}

/// Compares [a] and [b] in time that depends only on their lengths.
bool constantTimeEquals(String a, String b) {
  final left = utf8.encode(a);
  final right = utf8.encode(b);
  var diff = left.length ^ right.length;
  for (var i = 0; i < left.length; i++) {
    diff |= left[i] ^ (i < right.length ? right[i] : 0);
  }
  return diff == 0;
}

/// Guards the embedded API against callers other than the app itself (#425).
///
/// The embedded instance has no sign-in, so without this any local process or
/// any web page open in the browser could call it. In order, a request is
/// refused when:
///
/// - its `Host` is not `localhost:<port>` or `127.0.0.1:<port>` (403), which
///   stops DNS rebinding;
/// - it carries an `Origin` header (403): the native client never sends one,
///   a browser always does on cross-site writes;
/// - it has no `Authorization: Bearer <secret>` header, or the wrong secret
///   (401). `GET /health` is exempt so connectivity probes need no secret;
/// - it writes a body that is not `application/json` (415).
///
/// [port] is read per request because the socket is bound after the handler
/// is built. Only the embedded instance uses this; the hosted server keeps
/// `bearerAuth`.
Middleware embeddedGuard({
  required String secret,
  required int Function() port,
}) =>
    (inner) => (request) {
      final allowedHosts = {'localhost:${port()}', '127.0.0.1:${port()}'};
      if (!allowedHosts.contains(request.headers['host']?.toLowerCase())) {
        return _refuse(
          403,
          'forbidden_host',
          'The Host header is not allowed.',
        );
      }
      if (request.headers.containsKey('origin')) {
        return _refuse(
          403,
          'forbidden_origin',
          'Cross-origin requests are not allowed.',
        );
      }
      final isHealth = request.method == 'GET' && request.url.path == 'health';
      if (!isHealth) {
        final header = request.headers['authorization'];
        final match = header == null
            ? null
            : RegExp(
                r'^bearer\s+(\S+)$',
                caseSensitive: false,
              ).firstMatch(header.trim());
        if (match == null || !constantTimeEquals(match.group(1)!, secret)) {
          return _refuse(
            401,
            'unauthorized',
            'A valid bearer token is required.',
          ).change(headers: {'www-authenticate': 'Bearer'});
        }
      }
      const safe = {'GET', 'HEAD', 'OPTIONS'};
      final hasBody =
          (request.contentLength ?? 0) > 0 ||
          (request.headers['transfer-encoding'] ?? '').contains('chunked');
      if (!safe.contains(request.method) &&
          hasBody &&
          request.mimeType != 'application/json') {
        return _refuse(
          415,
          'unsupported_media_type',
          'Writes must be application/json.',
        );
      }
      return inner(request);
    };

Response _refuse(int status, String code, String message) =>
    errorResponse(status, code, message);
