import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';

const String serverName = 'soar_score_server';
const String serverDisplayName = 'Soar Score API Server';
const String serverVersion = '0.1.0';

/// Current server identity, serialized through the shared [HealthDto] so the
/// server and the API client (`soar_score_api`) cannot drift apart.
HealthDto identity() => HealthDto(
  name: serverName,
  displayName: serverDisplayName,
  version: serverVersion,
);

Response jsonResponse(Map<String, dynamic> body) => Response(
  200,
  body: jsonEncode(body),
  headers: <String, Object>{'content-type': 'application/json; charset=utf-8'},
);

/// `GET /health` — public health payload.
Handler createHealthHandler() {
  final router = Router()
    ..get('/health', (Request request) => jsonResponse(identity().toJson()));
  return router.call;
}
