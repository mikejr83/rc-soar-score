import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';
import '../../../services/workspace/next_step/next_step_action.dart';
import '../../../services/workspace/next_step/next_step_target.dart';
import '../../../services/workspace/next_step/next_step_text.dart';
import '../../not_wired_up_dialog.dart';

/// Where each next-step button goes.
///
/// One entry per target, so the ticket that builds a destination changes one
/// line: #123 scoring, #121 participants, #124 reports, #125 publish, #250
/// completion and #264 the matrix round. The in-place targets
/// ([NextStepTarget.openScoring], [NextStepTarget.unlock] and
/// [NextStepTarget.dismissSuggestion]) are handled by the card.
abstract final class NextStepNavigator {
  /// True for the targets the card handles itself.
  static bool isInPlace(NextStepTarget target) => switch (target) {
    NextStepTarget.openScoring ||
    NextStepTarget.unlock ||
    NextStepTarget.dismissSuggestion => true,
    _ => false,
  };

  /// Opens the destination of [action] for [contestId].
  static void open(
    BuildContext context,
    NextStepAction action, {
    required String contestId,
  }) {
    switch (action.target) {
      case NextStepTarget.configuration:
        context.go(contestConfigurationPath(contestId));
      case NextStepTarget.matrix:
        // The round to draw is ignored until #264.
        context.go(contestMatrixPath(contestId));
      case NextStepTarget.participants:
        // The system Participants manager, until #121 selects per contest.
        context.go(participantsPath);
      case NextStepTarget.scoring:
        showNotWiredUpDialog(
          context,
          'Scoring',
          detail: _scoringDetail(action),
        );
      case NextStepTarget.reports:
        showNotWiredUpDialog(
          context,
          'Reports',
          detail: 'The reports page is not built yet.',
        );
      case NextStepTarget.publish:
        showNotWiredUpDialog(
          context,
          'Publish',
          detail: 'The publish flow is not built yet.',
        );
      case NextStepTarget.completeDialog:
        showNotWiredUpDialog(
          context,
          'Complete contest',
          detail: 'The completion confirmation is not built yet.',
        );
      case NextStepTarget.openScoring ||
          NextStepTarget.unlock ||
          NextStepTarget.dismissSuggestion:
        throw ArgumentError.value(
          action.target,
          'action',
          'is handled in place by the card',
        );
    }
  }

  static String _scoringDetail(NextStepAction action) {
    final round = action.round;
    final group = action.group;
    if (round == null || group == null) {
      return 'Score entry is not built yet.';
    }
    return 'Score entry is not built yet. It will open at round $round, '
        'group ${NextStepText.group(group)}.';
  }
}
