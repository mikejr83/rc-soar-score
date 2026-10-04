import 'package:json_annotation/json_annotation.dart';

/// Whether a role flies and receives scores.
///
/// Serializes as the exact text in `plan/data-model/entities/role.md`.
enum RoleType {
  @JsonValue('Pilot')
  pilot,
  @JsonValue('NonFlier')
  nonFlier,
}
