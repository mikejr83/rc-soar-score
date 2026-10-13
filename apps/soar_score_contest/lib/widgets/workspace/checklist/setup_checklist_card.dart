import 'package:flutter/material.dart';

import '../../../services/workspace/checklist/checklist_item.dart';
import '../../../services/workspace/checklist/setup_checklist.dart';
import 'checklist_row.dart';

/// The Setup checklist card: a header with the required-items summary, the
/// required rows, then the optional rows under their own marked heading.
class SetupChecklistCard extends StatelessWidget {
  const SetupChecklistCard({
    super.key,
    required this.checklist,
    required this.onOpen,
  });

  final SetupChecklist checklist;
  final ValueChanged<ChecklistTarget> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('setup-checklist-card'),
      margin: EdgeInsets.zero,
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Semantics(
              header: true,
              child: Text('Setup checklist', style: theme.textTheme.titleLarge),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              checklist.summary,
              key: const ValueKey('setup-checklist-summary'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final item in checklist.required)
            ChecklistRow(item: item, onPressed: () => onOpen(item.target)),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Semantics(
              header: true,
              child: Row(
                children: [
                  Text('Optional', style: theme.textTheme.titleSmall),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Not needed to run the contest',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final item in checklist.optional)
            ChecklistRow(item: item, onPressed: () => onOpen(item.target)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
