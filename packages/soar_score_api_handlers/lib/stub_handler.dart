import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';

import 'health_handler.dart';

/// Placeholder API endpoints.
///
/// This file is a stopgap so the API surface exists while real endpoints are
/// being built. It is safe to delete once the real handlers take over.
Handler createStubApiHandler(HealthDto identity) {
  final router = Router()
    ..get('/meta', (Request request) => jsonResponse(identity.toJson()))
    ..get(
      '/ping',
      (Request request) => jsonResponse(<String, Object>{'status': 'ok'}),
    );
  return router.call;
}
