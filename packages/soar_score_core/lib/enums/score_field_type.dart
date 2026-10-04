import 'package:json_annotation/json_annotation.dart';

/// Data type of a score-entry field value.
///
/// Serializes as the exact text in `plan/data-model/entities/discipline_scorefield.md`.
enum ScoreFieldType {
  @JsonValue('string')
  string,
  @JsonValue('int')
  int,
  @JsonValue('float')
  float,
  @JsonValue('bool')
  bool,
  @JsonValue('enum')
  enumeration,
  @JsonValue('date')
  date,
  @JsonValue('time')
  time,
  @JsonValue('landing')
  landing,
}
