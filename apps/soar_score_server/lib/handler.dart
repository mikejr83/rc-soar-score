import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'health_handler.dart';
import 'stub_handler.dart';

/// Builds the application's top-level [Handler].
///
/// Each endpoint group lives in its own file and returns a self-contained
/// [Handler]; this is where they are composed. New endpoint groups can be
/// added by creating a handler file and mounting it here.
///
/// Served routes:
/// - `GET /health` — public health payload.
/// - `GET /api/v1/meta` — placeholder identifying the API.
/// - `GET /api/v1/ping` — placeholder liveness probe.
Handler createServerHandler() {
  final app = Router()
    ..mount('/', createHealthHandler())
    ..mount('/api/v1', createStubApiHandler());
  return app.call;
}
