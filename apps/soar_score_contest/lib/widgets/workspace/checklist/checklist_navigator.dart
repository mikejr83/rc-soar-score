import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';
import '../../../services/workspace/checklist/checklist_item.dart';
import '../../../services/workspace/workspace_control_target.dart';
import '../workspace_focus_link.dart';

/// Where each checklist row goes.
abstract final class ChecklistNavigator {
  /// Opens the destination of [target] for [contestId].
  ///
  /// The control targets focus the card on the workspace the director is
  /// already on; from anywhere else they open the workspace on that card.
  static void open(
    BuildContext context,
    ChecklistTarget target, {
    required String contestId,
  }) {
    switch (target) {
      case ChecklistTarget.configuration:
        context.go(contestConfigurationPath(contestId));
      case ChecklistTarget.participants:
        // The system Participants manager, until #121 selects per contest.
        context.go(participantsPath);
      case ChecklistTarget.matrix:
        context.go(contestMatrixPath(contestId));
      case ChecklistTarget.publicationControl:
        _focus(context, WorkspaceControlTarget.publication, contestId);
      case ChecklistTarget.scoringControl:
        _focus(context, WorkspaceControlTarget.scoring, contestId);
    }
  }

  static void _focus(
    BuildContext context,
    WorkspaceControlTarget control,
    String contestId,
  ) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    final focused =
        WorkspaceFocusLinkScope.maybeOf(context)
            ?.focus(control, animate: animate) ??
        false;
    if (!focused) {
      context.go(contestWorkspacePathFor(contestId, control));
    }
  }
}
