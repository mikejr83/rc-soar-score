import '../scoring/profile/scoring_issue.dart';

/// Thrown when a component set is rejected by its scoring profile.
///
/// Invalid input is rejected, never silently repaired.
class ScoringValidationError implements Exception {
  ScoringValidationError(List<ScoringIssue> issues)
    : issues = List.unmodifiable(issues);

  final List<ScoringIssue> issues;

  @override
  String toString() =>
      'ScoringValidationError: ${issues.map((i) => i.message).join('; ')}';
}
