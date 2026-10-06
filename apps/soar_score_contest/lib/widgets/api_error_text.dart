import 'package:soar_score_api/soar_score_api.dart';

/// A short, user-facing description of [error] from an API call.
///
/// Uses the server's own message when it sent one, so rule failures such as
/// "participant has participations" reach the director unchanged.
String apiErrorText(Object error) {
  if (error is ApiHttpError) {
    return error.error?.message ?? 'The request failed (${error.statusCode}).';
  }
  if (error is ApiNetworkError) {
    return 'The server could not be reached.';
  }
  return '$error';
}
