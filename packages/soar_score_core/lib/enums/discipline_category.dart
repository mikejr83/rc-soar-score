import 'package:json_annotation/json_annotation.dart';

/// Grouping of a discipline for selection (`DisciplineProfile.category`).
///
/// Serializes as the exact text in `plan/data-model/entities/discipline_profile.md`.
enum DisciplineCategory {
  @JsonValue('duration')
  duration,
  @JsonValue('multiple')
  multiple,
  @JsonValue('other')
  other,
}
