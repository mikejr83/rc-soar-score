import 'package:json_annotation/json_annotation.dart';

/// How a participant-to-account link arose.
///
/// Serializes as the exact text in `plan/data-model/entities/participant_account_link.md`.
enum ParticipantLinkOrigin {
  @JsonValue('EmailMatch')
  emailMatch,
  @JsonValue('DirectoryPull')
  directoryPull,
  @JsonValue('InvitationRedemption')
  invitationRedemption,
}
