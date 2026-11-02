import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';
import '../../../services/workspace/next_step/next_step_action.dart';
import '../../../services/workspace/next_step/next_step_target.dart';

/// Where each next-step button goes.
///
/// One entry per target, so the ticket that builds a destination changes one
/// line: the publish target opens the Publication page (#125). The
/// in-place targets ([NextStepTarget.openScoring],
/// [NextStepTarget.unlock], [NextStepTarget.completeDialog] and
/// [NextStepTarget.dismissSuggestion]) are handled by the card.
abstract final class NextStepNavigator {
  /// True for the targets the card handles itself.
  static bool isInPlace(NextStepTarget target) => switch (target) {
    NextStepTarget.openScoring ||
    NextStepTarget.unlock ||
    NextStepTarget.completeDialog ||
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
        context.go(contestMatrixPath(contestId, intent: action.matrixIntent));
      case NextStepTarget.participants:
        context.go(contestParticipantsPath(contestId));
      case NextStepTarget.scoring:
        context.go(
          contestScoringPath(
            contestId,
            round: action.round,
            group: action.round == null ? null : action.group,
          ),
        );
      case NextStepTarget.reports:
        context.go(contestReportsPath(contestId));
      case NextStepTarget.publish:
        context.go(contestPublicationPath(contestId));
      case NextStepTarget.openScoring ||
          NextStepTarget.unlock ||
          NextStepTarget.completeDialog ||
          NextStepTarget.dismissSuggestion:
        throw ArgumentError.value(
          action.target,
          'action',
          'is handled in place by the card',
        );
    }
  }
}
