import 'package:shelf/shelf.dart';

import 'cors.dart';
import 'error_mapping.dart';
import 'request_id.dart';
import 'request_logging.dart';

export 'cors.dart';
export 'error_mapping.dart';
export 'request_id.dart';
export 'request_logging.dart';

/// The shared pipeline around every route: request id (outermost), request
/// logging, then error mapping, so the log sees the mapped status.
///
/// [corsAllowedOrigins] lets browser apps from those origins call the API; see
/// [corsMiddleware]. It sits outside request logging and everything else, so
/// preflights skip the auth layer.
Handler withCommonMiddleware(
  Handler inner, {
  Set<String> corsAllowedOrigins = const {},
}) => const Pipeline()
    .addMiddleware(corsMiddleware(corsAllowedOrigins))
    .addMiddleware(requestIdMiddleware())
    .addMiddleware(requestLoggingMiddleware())
    .addMiddleware(errorMappingMiddleware())
    .addHandler(inner);
