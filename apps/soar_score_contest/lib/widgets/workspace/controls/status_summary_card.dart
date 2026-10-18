import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../services/workspace/publication_facts.dart';
import '../../../services/workspace/controls/status_summary.dart';
import '../workspace_scope.dart';

/// The contest's independent state values, each labelled, so none is guessed
/// from another. Text carries every value; the icons are decoration.
class StatusSummaryCard extends StatelessWidget {
  const StatusSummaryCard({super.key, required this.contest});

  final Contest contest;

  static IconData _icon(String id) => switch (id) {
    'lifecycle' => Icons.timeline,
    'scoring' => Icons.edit_note,
    'administration' => Icons.lock_outline,
    'publication' => Icons.publish,
    'visibility' => Icons.visibility_outlined,
    'results' => Icons.visibility_off_outlined,
    _ => Icons.archive_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final publication =
        WorkspaceScope.of(context).facts?.publication ??
        PublicationFacts.unknown;
    final values = StatusSummary.of(contest, publication);
    return Card(
      key: const ValueKey('status-summary'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final value in values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  key: ValueKey('status-${value.id}'),
                  children: [
                    Icon(
                      _icon(value.id),
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(value.label)),
                    Text(
                      value.value,
                      key: ValueKey('status-${value.id}-value'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
