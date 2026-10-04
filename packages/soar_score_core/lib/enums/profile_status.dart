import 'package:json_annotation/json_annotation.dart';

/// Lifecycle status of a profile version (`DisciplineProfile.status`).
///
/// Serializes as the exact text in `plan/data-model/entities/discipline_profile.md`.
enum ProfileStatus {
  @JsonValue('drafted')
  drafted,
  @JsonValue('published')
  published,
  @JsonValue('superseded')
  superseded,
}
