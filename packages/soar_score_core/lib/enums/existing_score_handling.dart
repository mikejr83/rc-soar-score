import 'package:json_annotation/json_annotation.dart';

/// What a move does to a score already accepted.
///
/// Serializes as the exact text in `plan/data-model/entities/matrix_assignment.md`.
enum ExistingScoreHandling {
  @JsonValue('None')
  none,
  @JsonValue('Reset')
  reset,
}
