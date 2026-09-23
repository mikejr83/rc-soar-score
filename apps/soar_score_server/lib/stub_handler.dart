import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'health_handler.dart';

/// Placeholder API endpoints.
///
/// This file is a stopgap so the API surface exists while real endpoints are
/// being built. It is safe to delete once the real handlers take over.
Handler createStubApiHandler() {
  final router = Router()
    ..get('/meta', (Request request) => jsonResponse(identity().toJson()))
    ..get(
      '/ping',
      (Request request) => jsonResponse(<String, Object>{'status': 'ok'}),
    );
  return router.call;
}
