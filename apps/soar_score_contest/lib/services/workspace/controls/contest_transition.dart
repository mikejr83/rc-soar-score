import 'package:soar_score_core/soar_score_core.dart';

/// What the snackbar says after the transition. The next-step card and the
/// control cards share these texts.
const String scoringOpenedMessage =
    'Participant scoring opened. Pilots and helpers can enter their own '
    'scores.';
const String scoringClosedMessage =
    'Participant scoring closed. Only directors can enter scores now.';
const String unlockedMessage =
    'Administration unlocked. Configuration, participants and the matrix can '
    'be changed.';
const String lockedMessage =
    'Administration locked. Configuration, participants, the matrix and '
    'scores cannot be changed until it is unlocked.';
const String completedMessage =
    'Contest completed. Participant scoring is closed and the results are '
    'final.';

/// A change a director makes to a contest's state with the contest actions
/// API (`POST /contests/{id}/actions`).
enum ContestTransition {
  openScoring(
    action: ContestAction.openScoring,
    undo: ContestAction.closeScoring,
    what: 'participant scoring',
    done: scoringOpenedMessage,
    label: 'Open scoring',
    busyLabel: 'Opening…',
  ),
  closeScoring(
    action: ContestAction.closeScoring,
    undo: ContestAction.openScoring,
    what: 'participant scoring',
    done: scoringClosedMessage,
    label: 'Close scoring',
    busyLabel: 'Closing…',
  ),
  lock(
    action: ContestAction.lock,
    undo: ContestAction.unlock,
    what: 'administration',
    done: lockedMessage,
    label: 'Lock administration',
    busyLabel: 'Locking…',
  ),
  unlock(
    action: ContestAction.unlock,
    undo: ContestAction.lock,
    what: 'administration',
    done: unlockedMessage,
    label: 'Unlock administration',
    busyLabel: 'Unlocking…',
  ),
  // A completed contest cannot go back, so there is no Undo.
  complete(
    action: ContestAction.complete,
    undo: null,
    what: 'the contest',
    done: completedMessage,
    label: 'Complete contest',
    busyLabel: 'Completing…',
  );

  const ContestTransition({
    required this.action,
    required this.undo,
    required this.what,
    required this.done,
    required this.label,
    required this.busyLabel,
  });

  final ContestAction action;

  /// The action that takes it back; `null` when nothing does.
  final ContestAction? undo;

  /// What changes, for the stale-page banner ("Your change to … wasn't
  /// applied").
  final String what;

  /// The snackbar text after success.
  final String done;

  /// The button's label.
  final String label;

  /// The button's label while the action runs.
  final String busyLabel;
}
