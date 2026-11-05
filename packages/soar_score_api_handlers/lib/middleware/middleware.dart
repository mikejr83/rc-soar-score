import 'package:shelf/shelf.dart';

import 'cors.dart';
import 'error_mapping.dart';
import 'request_id.dart';
import 'request_logging.dart';
import 'security_headers.dart';

export 'cors.dart';
export 'error_mapping.dart';
export 'in_flight_requests.dart';
export 'request_id.dart';
export 'request_logging.dart';
export 'security_headers.dart';

/// The shared pipeline around every route: request id (outermost), request
/// logging, then error mapping, so the log sees the mapped status.
///
/// [corsAllowedOrigins] lets browser apps from those origins call the API; see
/// [corsMiddleware]. It sits outside request logging and everything else, so
/// preflights skip the auth layer. [securityHeadersMiddleware] is outermost
/// so every response, preflights and errors included, carries its headers.
Handler withCommonMiddleware(
  Handler inner, {
  Set<String> corsAllowedOrigins = const {},
}) => const Pipeline()
    .addMiddleware(securityHeadersMiddleware())
    .addMiddleware(corsMiddleware(corsAllowedOrigins))
    .addMiddleware(requestIdMiddleware())
    .addMiddleware(requestLoggingMiddleware())
    .addMiddleware(errorMappingMiddleware())
    .addHandler(inner);
