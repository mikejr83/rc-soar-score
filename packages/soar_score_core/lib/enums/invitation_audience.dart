import 'package:json_annotation/json_annotation.dart';

/// Who an invitation is for.
///
/// Serializes as the exact text in `plan/data-model/entities/invitation.md`.
enum InvitationAudience {
  @JsonValue('Pilot')
  pilot,
  @JsonValue('Helper')
  helper,
}
