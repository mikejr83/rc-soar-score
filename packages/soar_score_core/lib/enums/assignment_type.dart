import 'package:json_annotation/json_annotation.dart';

/// How a matrix assignment row came to exist.
///
/// Serializes as the exact text in `plan/data-model/entities/matrix_assignment.md`.
enum AssignmentType {
  @JsonValue('Original')
  original,
  @JsonValue('Moved')
  moved,
  @JsonValue('Reflight')
  reflight,
  @JsonValue('LateAdd')
  lateAdd,
}
