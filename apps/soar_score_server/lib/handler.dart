import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

const String serverName = 'soar_score_server';
const String serverDisplayName = 'Soar Score API Server';
const String serverVersion = '0.1.0';

Map<String, Object> identityPayload() => <String, Object>{
      'name': serverName,
      'displayName': serverDisplayName,
      'version': serverVersion,
    };

Response jsonResponse(Map<String, Object> body) => Response(
      200,
      body: jsonEncode(body),
      headers: <String, Object>{
        'content-type': 'application/json; charset=utf-8',
      },
    );

/// Builds the application's top-level [Handler].
///
/// Served routes:
/// - `GET /health` — public health payload.
/// - `GET /api/v1/meta` — placeholder identifying the API.
/// - `GET /api/v1/ping` — placeholder liveness probe.
Handler createServerHandler() {
  final api = Router()
    ..get(
      '/meta',
      (Request request) => jsonResponse(identityPayload()),
    )
    ..get(
      '/ping',
      (Request request) => jsonResponse(<String, Object>{
            'status': 'ok',
          }),
    );

  final app = Router()
    ..get(
      '/health',
      (Request request) => jsonResponse(identityPayload()),
    )
    ..mount('/api/v1', api.call);
  return app.call;
}
