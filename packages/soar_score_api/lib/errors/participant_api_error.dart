import 'dart:convert';

import '../dto/participant_submit_dto.dart';
import 'api_http_error.dart';

/// Reads the self-scoring error body, which is a bare object with a `code`
/// (see [ParticipantErrorCodes]) and not the `{"error": ...}` envelope of the
/// director routes.
extension ParticipantApiHttpError on ApiHttpError {
  /// The participant error in the response body, or null when the body is not
  /// one (for example a gateway error page).
  ParticipantErrorDto? get participantError {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['code'] is String) {
        return ParticipantErrorDto.fromJson(decoded);
      }
    } on Object {
      // Not a participant error body.
    }
    return null;
  }
}
