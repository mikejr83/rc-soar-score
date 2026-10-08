import 'package:soar_score_core/soar_score_core.dart';

/// The facts about a drawn matrix the configuration page shows: its revision
/// and the smallest and largest group of any round.
class MatrixSummary {
  const MatrixSummary({
    required this.revisionNumber,
    required this.minGroupSize,
    required this.maxGroupSize,
    this.maxDuplicateMatchups,
    this.unmetOpponents,
  });

  /// `null` until a matrix is drawn.
  static MatrixSummary? of(CurrentMatrix matrix) {
    final revision = matrix.revision;
    if (revision == null) {
      return null;
    }
    final sizes = <(Id, int), int>{};
    for (final assignment in matrix.assignments) {
      if (assignment.supersededByAssignmentId != null) {
        continue;
      }
      final key = (assignment.scheduledRoundId, assignment.group);
      sizes[key] = (sizes[key] ?? 0) + 1;
    }
    final counts = sizes.values;
    final fairness = revision.fairnessSummary;
    return MatrixSummary(
      revisionNumber: revision.revisionNumber,
      minGroupSize: counts.isEmpty ? 0 : counts.reduce((a, b) => a < b ? a : b),
      maxGroupSize: counts.isEmpty ? 0 : counts.reduce((a, b) => a > b ? a : b),
      maxDuplicateMatchups: fairness?['max_duplicate_matchups'] as int?,
      unmetOpponents: fairness?['unmet_opponent_count'] as int?,
    );
  }

  final int revisionNumber;
  final int minGroupSize;
  final int maxGroupSize;

  /// From the fairness summary, when the draw recorded one.
  final int? maxDuplicateMatchups;
  final int? unmetOpponents;
}
