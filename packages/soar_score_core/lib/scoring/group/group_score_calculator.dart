import '../../enums/group_score_mode.dart';
import '../../errors/scoring_validation_error.dart';
import '../profile/scoring_issue.dart';
import 'final_rounding.dart';
import 'group_score_entry.dart';
import 'group_score_options.dart';
import 'pilot_round.dart';

/// Points given to the best pilot when scores are normalized.
const normalizedTopScore = 1000.0;

/// Computes the group score of every pilot in one group.
///
/// - `Raw`: the raw score.
/// - `Normalized`: raw score over the best raw score, times 1000.
/// - `Time`: time score over the best time score, times 1000, then the
///   landing bonus is added (the bonus is not part of the normalization).
///
/// Retired pilots are left out of the population that sets the best score and
/// receive a group score of zero. A group where the best score is zero scores
/// zero for the normalized part, with no division. Intermediate values are
/// never rounded; the configured rounding is applied once at the end.
List<GroupScoreEntry> calculateGroupScores(
  List<PilotRound> pilots,
  GroupScoreOptions options,
) {
  final ids = pilots.map((p) => p.pilotId).toSet();
  if (ids.length != pilots.length) {
    throw ScoringValidationError([
      const ScoringIssue(
        code: 'duplicate_pilot',
        message: 'A pilot appears twice in the group.',
      ),
    ]);
  }
  final eligible = pilots.where((p) => !p.retired);

  double best(double Function(PilotRound) score) =>
      eligible.fold(0.0, (max, p) => score(p) > max ? score(p) : max);

  double normalize(double score, double best) =>
      best == 0 ? 0 : score / best * normalizedTopScore;

  final bestRaw = best((p) => p.rawScore);
  final bestTime = best((p) => p.timeScore);

  double unrounded(PilotRound p) {
    if (p.retired) return 0;
    return switch (options.mode) {
      GroupScoreMode.raw => p.rawScore,
      GroupScoreMode.normalized => normalize(p.rawScore, bestRaw),
      GroupScoreMode.time => normalize(p.timeScore, bestTime) + p.landingBonus,
    };
  }

  return [
    for (final p in pilots)
      GroupScoreEntry(
        pilotId: p.pilotId,
        rawScore: p.rawScore,
        groupScore: applyFinalRounding(
          unrounded(p),
          options.roundingMode,
          options.decimalPlaces,
        ),
      ),
  ];
}
