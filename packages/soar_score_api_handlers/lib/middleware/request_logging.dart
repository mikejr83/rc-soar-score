import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import 'request_id.dart';

final _logger = Logger('Requests');

/// Logs one line per request: method, path, status, duration and request id.
///
/// Query strings and headers are left out on purpose, so tokens and other
/// secrets never reach the log. Server errors log at warning level.
Middleware requestLoggingMiddleware() =>
    (inner) => (request) async {
      final watch = Stopwatch()..start();
      final response = await inner(request);
      final level = response.statusCode >= 500 ? Level.WARNING : Level.INFO;
      _logger.log(
        level,
        '${request.method} /${request.url.path} -> ${response.statusCode} '
        '(${watch.elapsedMilliseconds} ms) request=${requestIdOf(request)}',
      );
      return response;
    };
