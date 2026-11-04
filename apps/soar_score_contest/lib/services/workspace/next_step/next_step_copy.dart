import 'package:soar_score_core/soar_score_core.dart';

import '../workspace_facts.dart';
import 'next_step.dart';
import 'next_step_action.dart';
import 'next_step_actions.dart';
import 'next_step_kind.dart';
import 'next_step_reason.dart';
import 'next_step_text.dart';
import 'next_step_tone.dart';

/// The words of each step, taken from the next-step card design.
///
/// [body] is the step's text in normal use. [lockedBody] is the same step
/// when administration is locked, which swaps the instruction for the reason
/// it can't be done.
abstract final class NextStepCopy {
  static String finishConfigurationBody(WorkspaceFacts f) =>
      f.configurationProblem ?? '${_wizardFacts(f)} ${_chooseOptions()}';

  static String _wizardFacts(WorkspaceFacts f) => f.scoringPilots == 0
      ? 'The contest has its details.'
      : 'The contest has its details and '
            '${NextStepText.count(f.scoringPilots, 'pilot')} from the wizard.';

  static String _chooseOptions() =>
      'Choose the scoring options on the Configuration page and save them.';

  static String addPilotsBody(WorkspaceFacts f) =>
      '${_pilotsSoFar(f)} '
      'The matrix needs at least 2 to draw groups.';

  static String _pilotsSoFar(WorkspaceFacts f) {
    if (f.scoringPilots == 0) {
      return 'No scoring pilots yet.';
    }
    final name = f.onlyPilotName;
    return 'Only 1 scoring pilot so far${name == null ? '' : ' ($name)'}.';
  }

  static String _drawReady(WorkspaceFacts f) {
    final revision = f.configuration?.revisionNumber;
    final pilots = f.teamCount > 0
        ? '${f.scoringPilots} scoring pilots in '
              '${NextStepText.count(f.teamCount, 'team')} are in.'
        : '${f.scoringPilots} scoring pilots are in.';
    return 'Configuration revision $revision is saved and valid, and $pilots';
  }

  static String drawMatrixBody(WorkspaceFacts f) =>
      '${_drawReady(f)} The draw happens on the Matrix page.';

  static const redrawBody =
      'The configuration has changed after the matrix was drawn. This change '
      'requires a new draw.';

  static String _matrixDrawn(WorkspaceFacts f) {
    final sizes = f.groupSizeMin == f.groupSizeMax
        ? '${f.groupSizeMax}'
        : '${f.groupSizeMin}–${f.groupSizeMax}';
    return 'Matrix is drawn: ${f.roundCount} rounds, ${f.groupCount} groups '
        'of $sizes.';
  }

  static String startScoringBody(WorkspaceFacts f) =>
      '${_matrixDrawn(f)} Enter scores or open online scoring. Contest moves '
      'to running after the first score is entered.';

  static const enterScoresBody =
      'Participant scoring is open. The contest moves to Running when the '
      'first score is accepted.';

  static String _groupProgress(WorkspaceFacts f) {
    final group = f.currentGroup;
    if (group == null) {
      return 'Open Scoring to continue.';
    }
    return 'Group ${NextStepText.group(group.groupNumber)} has '
        '${group.scored} of ${group.total} scores in.';
  }

  static String continueScoringBody(WorkspaceFacts f) {
    final next = f.currentGroup?.nextGroupNumber;
    final flies = next == null
        ? ''
        : ' Group ${NextStepText.group(next)} flies next.';
    return '${_groupProgress(f)}$flies';
  }

  static String drawNextBody(int round) =>
      'Rounds 1-${round - 1} have all scores entered. Seeded rounds are drawn '
      'one at a time from the current standings.';

  static const completeBody =
      'You decide when the contest is over. Nothing changes until you '
      'confirm.';

  /// The first sentence of a blocked step, for the substitution.
  static String lockedBody(NextStepKind kind, WorkspaceFacts f, int round) {
    const matrix = 'the matrix can’t change';
    const scores = 'scores can’t be entered';
    return switch (kind) {
      NextStepKind.finishConfiguration =>
        '${f.configurationProblem ?? _wizardFacts(f)} Administration is '
            'locked, so the configuration can’t change until you unlock it.',
      NextStepKind.addPilots =>
        '${_pilotsSoFar(f)} Administration is locked, so participants can’t '
            'change until you unlock it.',
      NextStepKind.drawMatrix =>
        '${_drawReady(f)} Administration is locked, so $matrix until you '
            'unlock it.',
      NextStepKind.redrawMatrix =>
        'The configuration has changed after the matrix was drawn. '
            'Administration is locked, so $matrix until you unlock it.',
      NextStepKind.startScoring =>
        '${_matrixDrawn(f)} Administration is locked, so $scores until you '
            'unlock it.',
      NextStepKind.enterScores =>
        'Participant scoring is open. Administration is locked, so $scores '
            'until you unlock it.',
      NextStepKind.continueScoring =>
        '${_groupProgress(f)} Administration is locked, so $scores until you '
            'unlock it.',
      NextStepKind.drawNextSeededRound =>
        'Rounds 1–${round - 1} have every score entered. Administration is '
            'locked, so $matrix until you unlock it.',
      _ => throw ArgumentError('$kind is not blocked by the lock'),
    };
  }

  static NextStepReason lockReason(WorkspaceFacts f) {
    final at = f.lockedAt;
    if (at == null) {
      return const NextStepReason(
        lead: 'Blocked:',
        text: 'administration is locked.',
        tone: NextStepTone.blocked,
      );
    }
    final by = f.lockedBy == null ? '' : ' by ${f.lockedBy}';
    return NextStepReason(
      lead: 'Blocked:',
      text:
          'administration locked$by at '
          '${NextStepText.when(at, f.contest.timezone)}.',
      tone: NextStepTone.blocked,
    );
  }

  /// "Then …" for a blocked [primary].
  static String thenNote(
    NextStepKind kind,
    NextStepAction primary,
    int round,
  ) => switch (kind) {
    NextStepKind.drawNextSeededRound =>
      'Then draw round $round on the Matrix page.',
    _ => 'Then ${NextStepText.lowerFirst(primary.label)}.',
  };

  static NextStepReason allScoresReason(WorkspaceFacts f) {
    final totals = {for (final round in f.rounds) round.total};
    final last = f.rounds.last.ordinal;
    final all = totals.length == 1 ? 'all ${totals.first}' : 'all its';
    return NextStepReason(
      lead: 'Why now:',
      text: 'every round has $all scores (rounds 1–$last).',
      tone: NextStepTone.positive,
    );
  }

  static NextStepReason idleReason(WorkspaceFacts f) => NextStepReason(
    lead: 'Why now:',
    text:
        'no new scores for 48 hours. The last was accepted '
        '${NextStepText.when(f.latestScore!.setAt, f.contest.timezone)}.',
    tone: NextStepTone.info,
  );

  static String publishBody(WorkspaceFacts f) {
    final at = f.completedAt;
    final completed = at == null
        ? 'The contest is completed.'
        : 'The contest was completed '
              '${NextStepText.when(at, f.contest.timezone)}.';
    return '$completed Results aren’t on the public site yet. Publishing '
        'first checks participants against the global pilot list.';
  }

  static String reportsBody(WorkspaceFacts f) {
    final publication = f.publication;
    final completedAt = f.completedAt;
    // Without publication details the card still dates the completion (#345).
    final completed = completedAt == null
        ? ''
        : 'The contest was completed '
              '${NextStepText.when(completedAt, f.contest.timezone)}. ';
    if (publication.needsSignIn) {
      return '${completed}Sign in to publish the results. '
          'Reports are available.';
    }
    if (!publication.isKnown) {
      return '${completed}Publication status can’t be loaded right now. '
          'Reports are available.';
    }
    if (!publication.supported) {
      return '${completed}Publishing is not available on this server. '
          'Reports are available.';
    }
    final at = publication.publishedAt;
    final published = at == null
        ? 'Results were published'
        : 'Results were published '
              '${NextStepText.when(at, f.contest.timezone)}';
    final visibility = switch (publication.visibility) {
      PublicationVisibility.unlisted => 'unlisted',
      PublicationVisibility.public => 'public',
      PublicationVisibility.delisted => 'delisted',
      null => 'public',
    };
    return '$published and are $visibility. Score corrections update the '
        'public site under the public update policy.';
  }

  static const afterDismissalBody =
      'Nothing new to score right now. Complete the contest from Contest '
      'controls when you’re ready.';

  /// Whether the lock replaces a step of this [kind].
  static bool blockedByLock(NextStepKind kind) => const {
    NextStepKind.finishConfiguration,
    NextStepKind.addPilots,
    NextStepKind.drawMatrix,
    NextStepKind.redrawMatrix,
    NextStepKind.startScoring,
    NextStepKind.enterScores,
    NextStepKind.continueScoring,
    NextStepKind.drawNextSeededRound,
  }.contains(kind);

  static NextStep unlockStep(NextStep blocked, WorkspaceFacts f, int round) =>
      NextStep(
        kind: NextStepKind.unlock,
        title: blocked.title,
        body: lockedBody(blocked.kind, f, round),
        reason: lockReason(f),
        primary: NextStepActions.unlock,
        note: thenNote(blocked.kind, blocked.primary, round),
      );
}
