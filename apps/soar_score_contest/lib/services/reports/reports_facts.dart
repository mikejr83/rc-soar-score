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
    required this.matrixRevision,
    required this.configurationRevision,
    required this.roundCount,
    required this.intendedTotalRounds,
    required this.isSeeded,
    required this.configDrift,
    required this.rounds,
    required this.standing,
    required this.scoresSignature,
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
      matrixRevision: workspace.matrix.revision?.revisionNumber,
      configurationRevision: workspace.configuration?.revisionNumber,
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
      scoresSignature: _signature(scores),
    );
  }

  final Contest contest;
  final bool hasMatrix;

  /// The current matrix revision number; `null` before the first draw.
  final int? matrixRevision;

  /// The latest saved configuration revision number; `null` when none.
  final int? configurationRevision;

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

  /// A digest of every score slot: its workflow state and the revision and
  /// time of its official score. It changes when a score is corrected even
  /// though the counts of scored slots do not.
  final int scoresSignature;

  static int _signature(ContestScores scores) => Object.hashAll([
    for (final slot in scores.slots)
      Object.hash(
        slot.placeholder.assignmentId,
        slot.placeholder.state,
        slot.placeholder.scoreRevision,
        slot.officialScore?.scoreRevision,
        slot.officialScore?.setAt,
      ),
  ]);

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

  /// Changes whenever something a report is built from changes: the contest,
  /// the matrix, the configuration or the scores. The viewer compares it to
  /// tell that its sheet is out of date.
  String get fingerprint => [
    contest.revision,
    matrixRevision,
    configurationRevision,
    roundCount,
    resultStatus.name,
    for (final round in rounds)
      '${round.ordinal}:${round.scored}/${round.total}',
    standing.unofficial,
    scoresSignature,
  ].join('|');
}
