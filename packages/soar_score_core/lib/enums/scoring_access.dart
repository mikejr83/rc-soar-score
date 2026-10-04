import 'package:json_annotation/json_annotation.dart';

/// Whether participants may submit scores.
///
/// Serializes as the exact text in `plan/data-model/entities/contest.md`.
enum ScoringAccess {
  @JsonValue('Closed')
  closed,
  @JsonValue('Open')
  open,
}
