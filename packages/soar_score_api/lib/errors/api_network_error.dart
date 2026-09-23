import 'api_exception.dart';

/// Thrown when no HTTP response could be obtained at all (connection
/// failure, timeout, DNS error, or a malformed response).
class ApiNetworkError extends ApiException {
  const ApiNetworkError(
    super.message, {
    required super.requestUri,
    this.cause,
  });

  /// Underlying transport error, if one was reported.
  final Object? cause;

  @override
  String toString() => cause == null
      ? 'ApiNetworkError($message) at $requestUri'
      : 'ApiNetworkError($message) at $requestUri, cause: $cause';
}
