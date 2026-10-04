import 'package:json_annotation/json_annotation.dart';

/// Why a pilot was excluded from a re-flight.
///
/// Serializes as the exact text in `plan/data-model/entities/re_flight_participant.md`.
enum ExcludedReason {
  @JsonValue('SameTeam')
  sameTeam,
  @JsonValue('Retired')
  retired,
  @JsonValue('NotEligible')
  notEligible,
  @JsonValue('DirectorExcluded')
  directorExcluded,
  @JsonValue('Declined')
  declined,
}
