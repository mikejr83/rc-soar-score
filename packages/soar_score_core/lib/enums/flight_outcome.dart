import 'package:json_annotation/json_annotation.dart';

/// Whether a calculated flight scored points or was a zero.
///
/// Serializes as the exact text in `plan/data-model/entities/flight_result.md`.
enum FlightOutcome {
  @JsonValue('Scored')
  scored,
  @JsonValue('Zero')
  zero,
}
