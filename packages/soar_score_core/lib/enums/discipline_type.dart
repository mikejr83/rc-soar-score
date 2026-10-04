import 'package:json_annotation/json_annotation.dart';

/// The discipline a profile scores (`DisciplineProfile.type`).
///
/// Serializes as the exact text in `plan/data-model/entities/discipline_profile.md`.
enum DisciplineType {
  @JsonValue('ALES')
  ales,
  @JsonValue('ThermalDuration')
  thermalDuration,
  @JsonValue('F3J')
  f3j,
  @JsonValue('F5J')
  f5j,
  @JsonValue('F3L')
  f3l,
  @JsonValue('F3K')
  f3k,
}
