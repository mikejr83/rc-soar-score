import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../services/workspace/checklist/setup_checklist.dart';
import '../workspace_scope.dart';
import 'checklist_navigator.dart';
import 'setup_checklist_card.dart';

/// The setup-checklist section of the workspace: works the rows out from the
/// workspace facts and connects them to their pages and controls.
class SetupChecklistSection extends StatelessWidget {
  const SetupChecklistSection({super.key, required this.contest});

  final Contest contest;

  @override
  Widget build(BuildContext context) {
    final scope = WorkspaceScope.of(context);
    final facts = scope.facts;
    if (facts == null) {
      return _Placeholder(
        onRetry: scope.factsFailed ? scope.reloadFacts : null,
      );
    }
    return SetupChecklistCard(
      checklist: SetupChecklist.resolve(facts),
      onOpen: (target) =>
          ChecklistNavigator.open(context, target, contestId: contest.id.value),
    );
  }
}

/// The card while the facts load, and when they could not be loaded.
class _Placeholder extends StatelessWidget {
  const _Placeholder({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('setup-checklist-placeholder'),
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: onRetry == null
            ? Row(
                children: [
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Loading the setup checklist…',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              )
            : Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: [
                  Text(
                    'The setup checklist could not be loaded.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    key: const ValueKey('setup-checklist-retry'),
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
      ),
    );
  }
}
