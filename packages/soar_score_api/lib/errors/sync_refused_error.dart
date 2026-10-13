import 'package:soar_score_core/soar_score_core.dart';

import 'api_http_error.dart';

/// Thrown when the service refuses a sync request outright and names the
/// reason in the error body's `code`, for example `schema_too_old` or
/// `reclaim_requires_sync`.
///
/// Per-mutation rejections are not errors: they come back in the exchange
/// response so one bad mutation never fails its batch.
class SyncRefusedError extends ApiHttpError {
  const SyncRefusedError(
    super.message, {
    required this.reason,
    required super.statusCode,
    required super.body,
    required super.requestUri,
  });

  /// Why the service refused the request.
  final SyncReasonCode reason;

  /// Whether the installation must be updated before it can sync again.
  bool get requiresUpdate =>
      reason == SyncReasonCode.unsupportedProtocolVersion ||
      reason == SyncReasonCode.schemaTooOld;
}
