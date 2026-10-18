import 'package:soar_score_core/soar_score_core.dart';

import '../workspace/workspace_round_fact.dart';
import 'result_status.dart';

/// What the scores entered so far say about standings produced now.
///
/// The standings run up to the last round that has a score. Within those
/// rounds a slot without a score, or with a score that is submitted or in
/// review, makes the result preliminary.
class ScoreStanding {
  const ScoreStanding._({
    required this.status,
    required this.lastScoredRound,
    required this.missingByRound,
    required this.unofficial,
  });

  /// Derives the standing from the [rounds] progress and the [slots] of the
  /// live matrix. [roundOfAssignment] maps each live assignment to its round's
  /// ordinal; a slot of any other assignment (superseded, cancelled round) is
  /// ignored.
  factory ScoreStanding.derive({
    required List<WorkspaceRoundFact> rounds,
    required Iterable<ScoreSlot> slots,
    required Map<Id, int> roundOfAssignment,
  }) {
    int? last;
    for (final round in rounds) {
      if (round.scored > 0 && (last == null || round.ordinal > last)) {
        last = round.ordinal;
      }
    }
    if (last == null) {
      return const ScoreStanding._(
        status: ResultStatus.none,
        lastScoredRound: null,
        missingByRound: {},
        unofficial: 0,
      );
    }
    final missing = <int, int>{};
    for (final round in rounds) {
      if (round.ordinal <= last && round.total > round.scored) {
        missing[round.ordinal] = round.total - round.scored;
      }
    }
    var unofficial = 0;
    for (final slot in slots) {
      final ordinal = roundOfAssignment[slot.placeholder.assignmentId];
      if (ordinal == null || ordinal > last) {
        continue;
      }
      final state = slot.placeholder.state;
      if (state == ScorePlaceholderState.submitted ||
          state == ScorePlaceholderState.inReview) {
        unofficial++;
      }
    }
    return ScoreStanding._(
      status: missing.isEmpty && unofficial == 0
          ? ResultStatus.official
          : ResultStatus.preliminary,
      lastScoredRound: last,
      missingByRound: Map.unmodifiable(missing),
      unofficial: unofficial,
    );
  }

  final ResultStatus status;

  /// The last round with a score; `null` when nothing is scored.
  final int? lastScoredRound;

  /// Missing scores by round ordinal, for rounds up to [lastScoredRound].
  final Map<int, int> missingByRound;

  /// Scores that are submitted or in review.
  final int unofficial;

  bool get hasScores => lastScoredRound != null;

  /// The first round that is missing scores, in ordinal order.
  int? get firstMissingRound {
    if (missingByRound.isEmpty) {
      return null;
    }
    return missingByRound.keys.reduce((a, b) => a < b ? a : b);
  }
}
