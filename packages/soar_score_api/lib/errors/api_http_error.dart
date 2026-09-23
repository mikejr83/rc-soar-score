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

  @override
  String toString() => 'ApiHttpError($statusCode: $message) at $requestUri';
}
