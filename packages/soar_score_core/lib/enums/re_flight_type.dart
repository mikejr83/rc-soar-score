import 'package:json_annotation/json_annotation.dart';

/// How a re-flight is flown.
///
/// Serializes as the exact text in `plan/data-model/entities/re_flight.md`.
enum ReFlightType {
  @JsonValue('MoveToGroup')
  moveToGroup,
  @JsonValue('RandomDraw')
  randomDraw,
  @JsonValue('ReflyEntireGroup')
  reflyEntireGroup,
}
