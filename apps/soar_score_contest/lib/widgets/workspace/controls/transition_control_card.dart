import 'package:material_ui/material_ui.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final (transition, current, scope, icon) = forControl(l10n, contest, control);
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
    AppLocalizations l10n,
    Contest contest,
    WorkspaceControl control,
  ) => switch (control) {
    WorkspaceControl.scoring =>
      contest.scoringAccess == ScoringAccess.open
          ? (
              ContestTransition.closeScoring,
              l10n.workspaceScoringOpen,
              l10n.workspaceScoringCloseScope,
              Icons.lock_clock,
            )
          : (
              ContestTransition.openScoring,
              l10n.workspaceScoringClosed,
              l10n.workspaceScoringOpenScope,
              Icons.edit_note,
            ),
    WorkspaceControl.administration =>
      contest.adminLock == AdminLock.locked
          ? (
              ContestTransition.unlock,
              l10n.workspaceAdminLocked,
              l10n.workspaceAdminUnlockScope,
              Icons.lock_open,
            )
          : (
              ContestTransition.lock,
              l10n.workspaceAdminUnlocked,
              l10n.workspaceAdminLockScope,
              Icons.lock,
            ),
    WorkspaceControl.lifecycle => (
      ContestTransition.complete,
      _title(contest.lifecycleState.name),
      l10n.workspaceCompleteScope,
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
