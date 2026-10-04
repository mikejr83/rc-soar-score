import 'package:json_annotation/json_annotation.dart';

/// A pilot's part in a re-flight.
///
/// Serializes as the exact text in `plan/data-model/entities/re_flight_participant.md`.
enum ReFlightParticipantRole {
  @JsonValue('Awarded')
  awarded,
  @JsonValue('Drawn')
  drawn,
  @JsonValue('GroupMember')
  groupMember,
  @JsonValue('Candidate')
  candidate,
  @JsonValue('Excluded')
  excluded,
}
