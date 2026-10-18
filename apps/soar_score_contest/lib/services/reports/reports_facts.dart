import 'package:soar_score_core/soar_score_core.dart';

import '../matrix/matrix_page_data.dart';
import '../workspace/workspace_facts.dart';
import '../workspace/workspace_round_fact.dart';
import 'result_status.dart';
import 'score_standing.dart';

/// What the reports page reads about one contest, reduced to plain values so
/// the availability rules stay pure functions.
///
/// Built from the workspace facts (rounds, drift, draw mode) so the rules that
/// decide them are the existing ones, not copies.
class ReportsFacts {
  const ReportsFacts._({
    required this.contest,
    required this.hasMatrix,
    required this.roundCount,
    required this.intendedTotalRounds,
    required this.isSeeded,
    required this.configDrift,
    required this.rounds,
    required this.standing,
  });

  /// Reduces [workspace] (derived from the same matrix data and [scores]) and
  /// the live assignments of [data]'s matrix.
  factory ReportsFacts.derive({
    required MatrixPageData data,
    required ContestScores scores,
    required WorkspaceFacts workspace,
  }) {
    final liveRounds = {
      for (final round in data.matrix.rounds)
        if (round.supersededByRoundId == null &&
            round.status != RoundStatus.cancelled)
          round.id: round.ordinal,
    };
    final roundOfAssignment = {
      for (final assignment in data.matrix.assignments)
        if (!assignment.isSuperseded &&
            liveRounds[assignment.scheduledRoundId] != null)
          assignment.id: liveRounds[assignment.scheduledRoundId]!,
    };
    return ReportsFacts._(
      contest: data.contest,
      hasMatrix: workspace.hasMatrix,
      roundCount: workspace.roundCount,
      intendedTotalRounds: workspace.intendedTotalRounds,
      isSeeded: workspace.drawMode == DrawMode.seededManOnMan,
      configDrift: workspace.configDrift,
      rounds: workspace.rounds,
      standing: ScoreStanding.derive(
        rounds: workspace.rounds,
        slots: scores.slots,
        roundOfAssignment: roundOfAssignment,
      ),
    );
  }

  final Contest contest;
  final bool hasMatrix;

  /// The drawn rounds that are not cancelled.
  final int roundCount;

  /// The total rounds the director intends to fly (seeded mode), if set.
  final int? intendedTotalRounds;
  final bool isSeeded;

  /// Settings that differ from those the matrix was drawn with.
  final List<String> configDrift;

  /// Each round's scoring progress.
  final List<WorkspaceRoundFact> rounds;
  final ScoreStanding standing;

  LifecycleState get lifecycle => contest.lifecycleState;
  bool get isCompleted => lifecycle == LifecycleState.completed;
  bool get hasScores => standing.hasScores;
  ResultStatus get resultStatus => standing.status;

  int get fullyScoredRounds => rounds
      .where((round) => round.total > 0 && round.scored == round.total)
      .length;

  int get partlyScoredRounds => rounds
      .where((round) => round.scored > 0 && round.scored < round.total)
      .length;

  int get notFlownRounds => rounds.where((round) => round.scored == 0).length;

  /// "6 of 8 rounds fully scored · 2 not flown".
  String get progressText {
    if (rounds.isEmpty) {
      return 'No rounds scored';
    }
    final full = fullyScoredRounds;
    final partly = partlyScoredRounds;
    final notFlown = notFlownRounds;
    return [
      if (full == 0 && partly == 0)
        'No rounds scored'
      else
        '$full of ${rounds.length} rounds fully scored',
      if (partly > 0)
        '$partly ${partly == 1 ? 'round' : 'rounds'} partly scored',
      if (notFlown > 0) '$notFlown not flown',
    ].join(' · ');
  }
}
