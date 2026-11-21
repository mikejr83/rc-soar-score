import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/workspace/controls/completion_blockers.dart';
import '../../../services/workspace/workspace_fact_source.dart';
import '../../../services/workspace/workspace_facts.dart';

/// Asks the director to confirm completing the contest, listing the scores
/// that are missing and the rounds nobody flew. Resolves to true when
/// confirmed.
///
/// [facts] is `null` when the workspace facts could not be loaded; the dialog
/// then says it cannot list what is open.
Future<bool> confirmComplete(
  BuildContext context, {
  required WorkspaceFacts? facts,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        key: const ValueKey('complete-dialog'),
        title: Text(l10n.workspaceCompleteTitle),
        content: SingleChildScrollView(
          child: _Body(l10n: l10n, facts: facts),
        ),
        actions: [
          TextButton(
            key: const ValueKey('complete-dialog-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            key: const ValueKey('complete-dialog-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.workspaceCompleteButton),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

class _Body extends StatelessWidget {
  const _Body({required this.l10n, required this.facts});

  final AppLocalizations l10n;
  final WorkspaceFacts? facts;

  @override
  Widget build(BuildContext context) {
    final facts = this.facts;
    final scoresKnown =
        facts != null &&
        !facts.unavailable.contains(WorkspaceFactSource.scores);
    final blockers = scoresKnown ? CompletionBlockers.of(facts) : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.workspaceCompleteLifecycle),
        const SizedBox(height: 12),
        Text(l10n.workspaceCompleteBody),
        const SizedBox(height: 12),
        if (blockers == null)
          Text(
            key: const ValueKey('complete-dialog-unknown'),
            l10n.workspaceCompleteScoresUnknown,
          )
        else if (blockers.isEmpty)
          Text(
            key: const ValueKey('complete-dialog-clear'),
            l10n.workspaceCompleteAllClear,
          )
        else ...[
          Text(l10n.workspaceCompleteStillOpen),
          const SizedBox(height: 4),
          if (blockers.missingScores > 0)
            Text(
              key: const ValueKey('complete-dialog-missing'),
              l10n.workspaceCompleteMissingScores(
                blockers.missingScores,
                blockers.missingScores == 1 ? 'flight has' : 'flights have',
              ),
            ),
          if (blockers.unflownRounds.isNotEmpty)
            Text(
              key: const ValueKey('complete-dialog-unflown'),
              l10n.workspaceCompleteUnflownRounds(
                blockers.unflownRounds.length == 1 ? 'Round' : 'Rounds',
                blockers.unflownRounds.join(', '),
              ),
            ),
        ],
      ],
    );
  }
}
