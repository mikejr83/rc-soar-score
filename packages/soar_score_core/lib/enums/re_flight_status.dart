import 'package:json_annotation/json_annotation.dart';

/// Where a re-flight stands.
///
/// Serializes as the exact text in `plan/data-model/entities/re_flight.md`.
enum ReFlightStatus {
  @JsonValue('Proposed')
  proposed,
  @JsonValue('DrawPending')
  drawPending,
  @JsonValue('AwaitingResponses')
  awaitingResponses,
  @JsonValue('ReadyToFly')
  readyToFly,
  @JsonValue('Finalized')
  finalized,
  @JsonValue('Cancelled')
  cancelled,
}
