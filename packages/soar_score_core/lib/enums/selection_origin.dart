import 'package:json_annotation/json_annotation.dart';

/// How an official score version was selected.
///
/// Serializes as the exact text in `plan/data-model/entities/official_score.md`.
/// Official status alone never says which of these happened.
enum SelectionOrigin {
  /// The director entered the score, or marked the stored submission official.
  @JsonValue('Manual')
  manual,

  /// The contest accepted the stored submission because its configured scope
  /// was fully scored. The official actor is null: the system acted.
  @JsonValue('Automatic')
  automatic,

  /// The director decided a review request.
  @JsonValue('ReviewDecision')
  reviewDecision,
}
