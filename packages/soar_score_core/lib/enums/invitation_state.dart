import 'package:json_annotation/json_annotation.dart';

/// Whether an invitation still grants access.
///
/// Serializes as the exact text in `plan/data-model/entities/invitation.md`.
enum InvitationState {
  @JsonValue('Active')
  active,
  @JsonValue('Replaced')
  replaced,
  @JsonValue('Revoked')
  revoked,
  @JsonValue('Expired')
  expired,
}
