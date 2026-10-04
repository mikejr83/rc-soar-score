import 'package:json_annotation/json_annotation.dart';

/// Data type of a configuration field value.
///
/// Serializes as the exact text in `plan/data-model/entities/discipline_configfield.md`.
enum ConfigFieldType {
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
  @JsonValue('landing')
  landing,
}
