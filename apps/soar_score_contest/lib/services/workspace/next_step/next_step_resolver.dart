import 'package:soar_score_core/soar_score_core.dart';

import '../workspace_facts.dart';
import 'completion_reminder.dart';
import 'next_step.dart';
import 'next_step_action.dart';
import 'next_step_actions.dart';
import 'next_step_copy.dart';
import 'next_step_kind.dart';
import 'next_step_reason.dart';
import 'next_step_target.dart';
import 'next_step_tone.dart';
import 'next_step_text.dart';

/// Chooses the one step the workspace suggests, and its words
/// (`resolveNextStep`).
///
/// The first matching rule wins; the rules and copy are in the next-step
/// resolver ticket (#343). When administration is locked a step that needs a
/// rejected change becomes an "unlock" step. A completion suggestion the
/// director dismissed becomes `continueScoringAfterDismissal`.
NextStep resolveNextStep(
  WorkspaceFacts facts, {
  required DateTime now,
  bool completionSuggestionDismissed = false,
}) {
  final kind = _kindOf(facts, now);
  if (completionSuggestionDismissed &&
      (kind == NextStepKind.completeAllScores ||
          kind == NextStepKind.completeIdle)) {
    return _afterDismissal;
  }
  final step = _build(kind, facts);
  if (facts.contest.adminLock == AdminLock.locked &&
      NextStepCopy.blockedByLock(kind)) {
    return NextStepCopy.unlockStep(step, facts, facts.roundCount + 1);
  }
  return step;
}

bool _allRoundsComplete(WorkspaceFacts f) =>
    f.rounds.isNotEmpty &&
    f.rounds.every((round) => round.total > 0 && round.scored == round.total);

/// For Standard every round is drawn up front. For Seeded there is another
/// round unless the intended total is known and already drawn.
bool _noMoreRounds(WorkspaceFacts f) {
  if (f.drawMode != DrawMode.seededManOnMan) {
    return true;
  }
  final intended = f.intendedTotalRounds;
  return intended != null && f.roundCount >= intended;
}

NextStepKind _kindOf(WorkspaceFacts f, DateTime now) {
  final lifecycle = f.contest.lifecycleState;
  if (lifecycle == LifecycleState.completed) {
    final p = f.publication;
    return p.isKnown && !p.isPublished && p.supported
        ? NextStepKind.publishResults
        : NextStepKind.viewReports;
  }
  if (lifecycle == LifecycleState.running) {
    final latest = f.latestScore;
    final complete = _allRoundsComplete(f);
    if (complete && _noMoreRounds(f)) {
      return NextStepKind.completeAllScores;
    }
    if (latest != null &&
        now.difference(latest.setAt) >= completionReminderAfter) {
      return NextStepKind.completeIdle;
    }
    if (complete && f.drawMode == DrawMode.seededManOnMan) {
      return NextStepKind.drawNextSeededRound;
    }
    return NextStepKind.continueScoring;
  }
  if (lifecycle == LifecycleState.created) {
    return NextStepKind.finishConfiguration;
  }
  if (!f.hasMatrix) {
    if (f.configurationProblem != null) {
      return NextStepKind.finishConfiguration;
    }
    return f.scoringPilots < 2
        ? NextStepKind.addPilots
        : NextStepKind.drawMatrix;
  }
  if (f.configDrift.isNotEmpty) {
    return NextStepKind.redrawMatrix;
  }
  // A Configuring contest that has a matrix and no drift is ready to score.
  return f.contest.scoringAccess == ScoringAccess.open
      ? NextStepKind.enterScores
      : NextStepKind.startScoring;
}

const _afterDismissal = NextStep(
  kind: NextStepKind.continueScoringAfterDismissal,
  title: 'Continue scoring',
  body: NextStepCopy.afterDismissalBody,
  primary: NextStepAction(
    label: 'Open Scoring',
    target: NextStepTarget.scoring,
  ),
);

NextStep _build(NextStepKind kind, WorkspaceFacts f) {
  switch (kind) {
    case NextStepKind.publishResults:
      return NextStep(
        kind: kind,
        title: 'Publish results',
        body: NextStepCopy.publishBody(f),
        primary: NextStepAction(
          label: 'Publish results…',
          target: NextStepTarget.publish,
          enabled: !f.isOffline,
          disabledNote: f.isOffline ? 'Needs a connection.' : null,
        ),
      );
    case NextStepKind.viewReports:
      return NextStep(
        kind: kind,
        title: 'View reports',
        body: NextStepCopy.reportsBody(f),
        primary: const NextStepAction(
          label: 'Open Reports',
          target: NextStepTarget.reports,
        ),
      );
    case NextStepKind.finishConfiguration:
      return NextStep(
        kind: kind,
        title: 'Finish the configuration',
        body: NextStepCopy.finishConfigurationBody(f),
        primary: NextStepActions.openConfiguration,
      );
    case NextStepKind.addPilots:
      return NextStep(
        kind: kind,
        title: 'Add at least 2 scoring pilots',
        body: NextStepCopy.addPilotsBody(f),
        primary: NextStepActions.openParticipants,
      );
    case NextStepKind.drawMatrix:
      return NextStep(
        kind: kind,
        title: 'Draw the matrix',
        body: NextStepCopy.drawMatrixBody(f),
        primary: NextStepActions.goToMatrix,
      );
    case NextStepKind.redrawMatrix:
      return NextStep(
        kind: kind,
        title: 'Redraw the matrix',
        body: NextStepCopy.redrawBody,
        reason: NextStepReason(
          lead: 'Changed since the draw:',
          text: f.configDrift.join(' '),
          tone: NextStepTone.warning,
        ),
        primary: NextStepActions.goToMatrix,
      );
    case NextStepKind.startScoring:
      return NextStep(
        kind: kind,
        title: 'Start scoring',
        body: NextStepCopy.startScoringBody(f),
        primary: const NextStepAction(
          label: 'Open online scoring',
          target: NextStepTarget.openScoring,
          busyLabel: 'Opening…',
        ),
        secondary: NextStepActions.scoring('Enter scores', round: 1, group: 1),
      );
    case NextStepKind.enterScores:
      return NextStep(
        kind: kind,
        title: 'Enter scores for round 1, group A',
        body: NextStepCopy.enterScoresBody,
        primary: NextStepActions.scoring(
          'Open Scoring at round 1, group A',
          round: 1,
          group: 1,
        ),
      );
    case NextStepKind.continueScoring:
      final round = f.currentGroup?.roundOrdinal ?? 1;
      final group = f.currentGroup?.groupNumber ?? 1;
      final where = 'round $round, group ${NextStepText.group(group)}';
      return NextStep(
        kind: kind,
        title: 'Continue scoring: $where',
        body: NextStepCopy.continueScoringBody(f),
        primary: NextStepActions.scoring(
          'Open Scoring at $where',
          round: round,
          group: group,
        ),
      );
    case NextStepKind.drawNextSeededRound:
      final round = f.roundCount + 1;
      return NextStep(
        kind: kind,
        title: 'Draw round $round',
        body: NextStepCopy.drawNextBody(round),
        primary: NextStepAction(
          label: 'Go to Matrix to draw round $round',
          target: NextStepTarget.matrix,
          round: round,
        ),
      );
    case NextStepKind.completeAllScores:
    case NextStepKind.completeIdle:
      return NextStep(
        kind: kind,
        isSuggestion: true,
        title: 'Complete the contest',
        body: NextStepCopy.completeBody,
        reason: kind == NextStepKind.completeAllScores
            ? NextStepCopy.allScoresReason(f)
            : NextStepCopy.idleReason(f),
        primary: NextStepActions.completeContest,
        secondary: NextStepActions.notYet,
      );
    case NextStepKind.continueScoringAfterDismissal:
    case NextStepKind.unlock:
      throw StateError('$kind is not chosen by a rule');
  }
}
