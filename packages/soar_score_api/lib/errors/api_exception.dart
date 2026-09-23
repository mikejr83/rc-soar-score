/// Base class for all errors thrown by the Soar Score API client.
///
/// Every error carries the [requestUri] of the call that failed so callers
/// can report which endpoint was targeted. Thrown directly for failures that
/// do not fit the typed subtypes (e.g. a 2xx body that cannot be decoded).
class ApiException implements Exception {
  const ApiException(this.message, {required this.requestUri});

  /// Human-readable description of the failure.
  final String message;

  /// The full URI of the request that caused the failure.
  final Uri requestUri;

  @override
  String toString() => '$runtimeType($message) at $requestUri';
}
