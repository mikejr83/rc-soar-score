import 'package:soar_score_contest/services/matrix/round_progress_view.dart';
import 'package:soar_score_contest/services/workspace/current_group_facts.dart';
import 'package:soar_score_contest/services/workspace/progress/progress_summary.dart';
import 'package:soar_score_contest/services/workspace/workspace_round_fact.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// One round of the progress summary tests: [scored] of [total] pilots, in
/// [groups] groups.
WorkspaceRoundFact progressRound(
  int ordinal,
  int scored, {
  int total = 24,
  int groups = 4,
}) => WorkspaceRoundFact(
  ordinal: ordinal,
  groupCount: groups,
  scored: scored,
  total: total,
  state: RoundProgressView.of(
    RoundStatus.open,
    scored: scored,
    total: total,
  ).state,
);

/// Rounds from [scored] counts, 24 pilots each, in 4 groups.
List<WorkspaceRoundFact> progressRounds(List<int> scored, {int total = 24}) => [
  for (var i = 0; i < scored.length; i++)
    progressRound(i + 1, scored[i], total: total),
];

ProgressSummary deriveProgress(
  List<WorkspaceRoundFact> rounds, {
  bool seeded = false,
  int? intended,
  CurrentGroupFacts? frontierGroup,
  DateTime? latestScoreAt,
  int scoreCount = 0,
  bool completed = false,
  bool scoresAvailable = true,
}) => ProgressSummary.derive(
  rounds: rounds,
  scoresAvailable: scoresAvailable,
  seeded: seeded,
  intendedTotalRounds: intended,
  roundCount: rounds.length,
  groupCount: 4,
  groupSizeMin: 6,
  groupSizeMax: 6,
  matrixRevision: 2,
  frontierGroup: frontierGroup,
  latestScoreAt: latestScoreAt,
  scoreCount: scoreCount,
  completed: completed,
);
