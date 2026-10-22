import 'package:soar_score_api/soar_score_api.dart';

/// What kind of failure an API call ended in, which decides how a page shows
/// it and which actions make sense.
enum ApiFailureKind {
  /// The server could not be reached, or failed on its side. Retrying can work.
  unavailable,

  /// The caller is not signed in (401).
  unauthorized,

  /// The caller is signed in but may not do this (403).
  forbidden,

  /// The thing changed or is in a state that rejects this change. What to do
  /// about it depends on the flow, so there is no generic resolution.
  conflict,

  /// The server rejected the content of the request. Retrying unchanged fails.
  validation,

  /// What was asked for does not exist (any more).
  notFound,

  /// Anything else, including a 400 or 409 whose code is not known here.
  other,
}

/// An API failure sorted by [kind], with the text to show.
class ApiFailure {
  const ApiFailure(this.kind, this.message);

  final ApiFailureKind kind;

  /// The server's own message when it sent one.
  final String message;

  /// Whether sending the same request again can succeed.
  bool get retryable => kind == ApiFailureKind.unavailable;

  /// Sorts [error], thrown by an API call.
  ///
  /// The server's stable error `code` decides first (`not_found`,
  /// `invalid_request`, `stale_revision`, `already_stored`,
  /// `already_superseded`, `internal_error`). Without a known code the status
  /// decides, but only where the status alone is unambiguous: 401, 403, 404
  /// and 5xx. A 400 or 409 with an unknown code is [ApiFailureKind.other], since
  /// 409 covers rule failures such as contest state and sync refusals that
  /// need their own handling.
  factory ApiFailure.of(Object error) {
    if (error is ApiNetworkError) {
      return const ApiFailure(
        ApiFailureKind.unavailable,
        'The server could not be reached.',
      );
    }
    if (error is! ApiHttpError) {
      return ApiFailure(ApiFailureKind.other, '$error');
    }
    final status = error.statusCode;
    final message = error.error?.message ?? 'The request failed ($status).';
    final byCode = switch (error.error?.code) {
      'not_found' => ApiFailureKind.notFound,
      'invalid_request' => ApiFailureKind.validation,
      'stale_revision' ||
      'already_stored' ||
      'already_superseded' => ApiFailureKind.conflict,
      'internal_error' => ApiFailureKind.unavailable,
      _ => null,
    };
    final kind =
        byCode ??
        switch (status) {
          401 => ApiFailureKind.unauthorized,
          403 => ApiFailureKind.forbidden,
          404 => ApiFailureKind.notFound,
          >= 500 => ApiFailureKind.unavailable,
          _ => ApiFailureKind.other,
        };
    return ApiFailure(kind, message);
  }
}
