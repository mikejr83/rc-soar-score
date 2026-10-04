import 'package:json_annotation/json_annotation.dart';

/// A pilot's answer to a re-flight offer.
///
/// Serializes as the exact text in `plan/data-model/entities/re_flight_participant.md`.
enum ReFlightResponse {
  @JsonValue('NotRequired')
  notRequired,
  @JsonValue('Pending')
  pending,
  @JsonValue('Accepted')
  accepted,
  @JsonValue('Declined')
  declined,
}
