import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/repositories/repository.dart';

final _logger = Logger('Main');

/// Serializes [body] as the standard API JSON response (200 unless
/// [statusCode] says otherwise).
Response jsonResponse(Map<String, dynamic> body, {int statusCode = 200}) =>
    Response(
      statusCode,
      body: jsonEncode(body),
      headers: <String, Object>{
        'content-type': 'application/json; charset=utf-8',
      },
    );

/// `GET /health` — public health payload.
///
/// [identity] is serialized through the shared [HealthDto] so the server,
/// the embedded instance, and the API client (`soar_score_api`) cannot drift
/// apart.
Handler createHealthHandler(
  String name,
  String displayName,
  String version,
  Repository repository,
) {
  final router = Router()
    ..get('/health', (Request request) {
      // Here you would typically gather health information.
      final healthInfo = HealthDto(
        name: name,
        displayName: displayName,
        version: version,
      );
      _logger.fine('Health check requested: ${healthInfo.toJson()}');
      return jsonResponse(healthInfo.toJson());
    });
  return router.call;
}
