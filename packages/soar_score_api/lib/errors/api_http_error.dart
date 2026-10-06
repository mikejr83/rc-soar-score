import 'dart:convert';

import '../dto/api_error_dto.dart';
import 'api_exception.dart';

/// Thrown when the server responds with a non-2xx status code.
class ApiHttpError extends ApiException {
  const ApiHttpError(
    super.message, {
    required this.statusCode,
    required this.body,
    required super.requestUri,
  });

  /// HTTP status code of the failure response.
  final int statusCode;

  /// Raw body of the failure response (UTF-8 decoded).
  final String body;

  /// The server's `{"error": {...}}` body, or null when the body is not one.
  ApiErrorDto? get error {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> &&
          decoded['error'] is Map<String, dynamic>) {
        return ApiErrorDto.fromJson(decoded['error'] as Map<String, dynamic>);
      }
    } on Object {
      // Not a JSON error body.
    }
    return null;
  }

  @override
  String toString() => 'ApiHttpError($statusCode: $message) at $requestUri';
}
