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

/// `GET /health` — public health payload.
Handler createHealthHandler() {
  final router = Router()
    ..get(
      '/health',
      (Request request) => jsonResponse(identityPayload()),
    );
  return router.call;
}
