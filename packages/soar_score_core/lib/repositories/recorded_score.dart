import '../models/contest/contest.dart';
import '../models/scores/official_score.dart';
import '../models/scores/score_attempt.dart';
import '../models/scores/score_placeholder.dart';

/// A score entry ready to store: the attempt, the official score taken from
/// it and the placeholder in its new state, with the contest when the entry
/// moved it on (the first accepted score changes `Ready` to `Running`).
///
/// `OfficialScoreRepository.recordEntry` stores all of it, or none.
class RecordedScore {
  const RecordedScore({
    required this.attempt,
    required this.officialScore,
    required this.placeholder,
    this.contest,
  });

  final ScoreAttempt attempt;
  final OfficialScore officialScore;

  /// The placeholder as it must be stored, at the revision it was read at.
  final ScorePlaceholder placeholder;

  /// The contest to store with the entry, or null when it does not change.
  final Contest? contest;
}
