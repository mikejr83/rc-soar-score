import 'package:flutter/material.dart';

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
    builder: (context) => AlertDialog(
      key: const ValueKey('complete-dialog'),
      title: const Text('Complete contest?'),
      content: SingleChildScrollView(child: _Body(facts: facts)),
      actions: [
        TextButton(
          key: const ValueKey('complete-dialog-cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('complete-dialog-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Complete contest'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class _Body extends StatelessWidget {
  const _Body({required this.facts});

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
        const Text('Lifecycle: Running → Completed'),
        const SizedBox(height: 12),
        const Text(
          'Completing closes participant scoring and ends results hiding. '
          'There is no way back to Running. Authorized score corrections '
          'stay possible.',
        ),
        const SizedBox(height: 12),
        if (blockers == null)
          const Text(
            key: ValueKey('complete-dialog-unknown'),
            'The scores could not be loaded, so the missing scores and '
            'unflown rounds are not listed.',
          )
        else if (blockers.isEmpty)
          const Text(
            key: ValueKey('complete-dialog-clear'),
            'Every flight has a score and every round has been flown.',
          )
        else ...[
          const Text('Still open:'),
          const SizedBox(height: 4),
          if (blockers.missingScores > 0)
            Text(
              key: const ValueKey('complete-dialog-missing'),
              '• ${blockers.missingScores} '
              '${blockers.missingScores == 1 ? 'flight has' : 'flights have'}'
              ' no score',
            ),
          if (blockers.unflownRounds.isNotEmpty)
            Text(
              key: const ValueKey('complete-dialog-unflown'),
              '• ${blockers.unflownRounds.length == 1 ? 'Round' : 'Rounds'} '
              '${blockers.unflownRounds.join(', ')} not flown',
            ),
        ],
      ],
    );
  }
}
