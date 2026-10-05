import 'package:shelf/shelf.dart';

import 'error_mapping.dart';
import 'request_id.dart';
import 'request_logging.dart';

export 'error_mapping.dart';
export 'request_id.dart';
export 'request_logging.dart';

/// The shared pipeline around every route: request id (outermost), request
/// logging, then error mapping, so the log sees the mapped status.
Handler withCommonMiddleware(Handler inner) => const Pipeline()
    .addMiddleware(requestIdMiddleware())
    .addMiddleware(requestLoggingMiddleware())
    .addMiddleware(errorMappingMiddleware())
    .addHandler(inner);
