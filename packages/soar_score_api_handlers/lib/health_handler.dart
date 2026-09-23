import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';

/// Serializes [body] as the standard API JSON 200 response.
Response jsonResponse(Map<String, dynamic> body) => Response(
  200,
  body: jsonEncode(body),
  headers: <String, Object>{'content-type': 'application/json; charset=utf-8'},
);

/// `GET /health` — public health payload.
///
/// [identity] is serialized through the shared [HealthDto] so the server,
/// the embedded instance, and the API client (`soar_score_api`) cannot drift
/// apart.
Handler createHealthHandler(HealthDto identity) {
  final router = Router()
    ..get('/health', (Request request) => jsonResponse(identity.toJson()));
  return router.call;
}
