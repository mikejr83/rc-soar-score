import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../services/workspace/controls/contest_transition.dart';
import '../../../services/workspace/controls/transition_availability.dart';
import '../../../services/workspace/workspace_control.dart';
import 'control_card_body.dart';
import 'transition_button.dart';

/// A control card whose one button makes a [ContestTransition]: scoring,
/// administration and lifecycle differ only in the words and the transition
/// that [forControl] picks from the contest.
class TransitionControlCard extends StatelessWidget {
  const TransitionControlCard({
    super.key,
    required this.contest,
    required this.control,
  });

  final Contest contest;
  final WorkspaceControl control;

  @override
  Widget build(BuildContext context) {
    final (transition, current, scope, icon) = forControl(contest, control);
    final availability = TransitionAvailability.of(contest, transition);
    return ControlCardBody(
      control: control,
      current: current,
      scope: scope,
      disabledReason: availability.reason,
      button: TransitionButton(
        contest: contest,
        transition: transition,
        icon: icon,
      ),
    );
  }

  /// The transition [control] offers for [contest] now, the current value,
  /// the scope sentence and the button's icon.
  static (ContestTransition, String, String, IconData) forControl(
    Contest contest,
    WorkspaceControl control,
  ) => switch (control) {
    WorkspaceControl.scoring =>
      contest.scoringAccess == ScoringAccess.open
          ? (
              ContestTransition.closeScoring,
              'Open',
              'Closing stops pilots and helpers from entering their own '
                  'scores.',
              Icons.lock_clock,
            )
          : (
              ContestTransition.openScoring,
              'Closed',
              'Opening lets pilots and helpers enter their own scores.',
              Icons.edit_note,
            ),
    WorkspaceControl.administration =>
      contest.adminLock == AdminLock.locked
          ? (
              ContestTransition.unlock,
              'Locked',
              'Unlocking allows changes to configuration, participants, the '
                  'matrix and scores again.',
              Icons.lock_open,
            )
          : (
              ContestTransition.lock,
              'Unlocked',
              'Locking blocks changes to configuration, participants, the '
                  'matrix and scores.',
              Icons.lock,
            ),
    WorkspaceControl.lifecycle => (
      ContestTransition.complete,
      _title(contest.lifecycleState.name),
      'Completing ends the contest: scoring closes and the results are final.',
      Icons.flag,
    ),
    _ => throw ArgumentError.value(
      control,
      'control',
      'has no contest transition',
    ),
  };

  static String _title(String name) =>
      '${name[0].toUpperCase()}${name.substring(1)}';
}
