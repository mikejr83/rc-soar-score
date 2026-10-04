import 'package:json_annotation/json_annotation.dart';

/// How a conflict was or will be resolved.
///
/// Serializes as the exact text in `plan/data-model/enumerations.md`.
enum ConflictResolution {
  @JsonValue('Pending')
  pending,
  @JsonValue('Automatic')
  automatic,
  @JsonValue('Manual')
  manual,
}
