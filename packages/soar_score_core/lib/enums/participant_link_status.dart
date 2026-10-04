import 'package:json_annotation/json_annotation.dart';

/// Where a participant-to-account link stands.
///
/// Serializes as the exact text in `plan/data-model/entities/participant_account_link.md`.
enum ParticipantLinkStatus {
  @JsonValue('Candidate')
  candidate,
  @JsonValue('Confirmed')
  confirmed,
  @JsonValue('Ended')
  ended,
}
