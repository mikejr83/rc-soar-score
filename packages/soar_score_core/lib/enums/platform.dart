import 'package:json_annotation/json_annotation.dart';

/// Where an installation runs.
///
/// Serializes as the exact text in `plan/data-model/enumerations.md`.
enum Platform {
  @JsonValue('Web')
  web,
  @JsonValue('Windows')
  windows,
  @JsonValue('Other')
  other,
}
