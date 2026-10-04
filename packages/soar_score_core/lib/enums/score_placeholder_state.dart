import 'package:json_annotation/json_annotation.dart';

/// The score workflow summary on a placeholder.
///
/// Serializes as the exact text in `plan/data-model/entities/score_placeholder.md`.
enum ScorePlaceholderState {
  @JsonValue('NotEntered')
  notEntered,
  @JsonValue('Submitted')
  submitted,
  @JsonValue('InReview')
  inReview,
  @JsonValue('Official')
  official,
}
