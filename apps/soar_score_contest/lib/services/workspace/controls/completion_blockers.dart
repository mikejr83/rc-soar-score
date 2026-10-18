import '../../matrix/round_progress_view.dart';
import '../workspace_facts.dart';

/// What is still open when a director completes the contest: flights without
/// a score and rounds nobody flew. Completing is still allowed; the dialog
/// only names these so the director decides knowingly.
class CompletionBlockers {
  const CompletionBlockers({
    required this.missingScores,
    required this.unflownRounds,
  });

  /// Reads the blockers from [facts]; empty when the scores are unavailable,
  /// which the dialog says separately.
  factory CompletionBlockers.of(WorkspaceFacts facts) {
    var missing = 0;
    final unflown = <int>[];
    for (final round in facts.rounds) {
      switch (round.state) {
        case RoundProgressState.inProgress:
          missing += round.total - round.scored;
        case RoundProgressState.notFlown:
          unflown.add(round.ordinal);
        case RoundProgressState.scored || RoundProgressState.cancelled:
          break;
      }
    }
    return CompletionBlockers(
      missingScores: missing,
      unflownRounds: List.unmodifiable(unflown),
    );
  }

  /// Flights without a score in rounds that were started.
  final int missingScores;

  /// The ordinals of the rounds with no scores at all.
  final List<int> unflownRounds;

  bool get isEmpty => missingScores == 0 && unflownRounds.isEmpty;
}
