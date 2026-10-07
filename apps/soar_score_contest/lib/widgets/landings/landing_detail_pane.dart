import 'package:flutter/material.dart';
import 'package:soar_score_api/soar_score_api.dart';

import 'landing_unit_text.dart';

/// The detail pane of the Landings page: the selected table's name and
/// state, the copy and delete actions, and its entries.
///
/// A table never changes, so there is no edit: "Create copy" opens the form
/// pre-filled to make a new table. A system table or a table a contest
/// uses is locked, and its delete action shows why it is unavailable.
/// [onBack] shows a back arrow when only the detail is visible.
class LandingDetailPane extends StatelessWidget {
  const LandingDetailPane({
    super.key,
    required this.view,
    required this.onCopy,
    required this.onDelete,
    this.onBack,
  });

  final LandingTableView view;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback? onBack;

  /// Why [view] cannot be removed, or `null` when it can.
  String? get lockedReason => view.table.isSystem
      ? 'System tables are read-only and cannot be removed.'
      : view.inUse
      ? 'Locked: a contest uses this table, so it cannot be removed.'
      : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = lockedReason;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      children: [
        Row(
          children: [
            if (onBack != null)
              IconButton(
                key: const ValueKey('landing-detail-back'),
                tooltip: 'Back to landings',
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(view.table.name, style: theme.textTheme.headlineSmall),
                  Text(
                    '${landingUnitLabel(view.table.inputUnit)} · '
                    '${view.results.length} entries',
                    style: muted,
                  ),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              key: const ValueKey('copy-landing'),
              onPressed: onCopy,
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: const Text('Create copy'),
            ),
            if (locked == null)
              IconButton(
                key: const ValueKey('delete-landing'),
                tooltip: 'Delete ${view.table.name}',
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              )
            else
              Tooltip(
                message: locked,
                child: const IconButton(
                  key: ValueKey('delete-landing-locked'),
                  icon: Icon(Icons.lock_outline),
                  onPressed: null,
                ),
              ),
          ],
        ),
        if (locked != null) ...[
          const SizedBox(height: 16),
          Card(
            key: const ValueKey('landing-locked-notice'),
            margin: EdgeInsets.zero,
            color: theme.colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$locked A table never changes; create a copy to '
                      'make a different one.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(),
              },
              children: [
                TableRow(
                  children: [
                    for (final heading in ['Key', 'Label', 'Points'])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          heading,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                for (final entry in view.results)
                  TableRow(
                    children: [
                      for (final text in [
                        entry.entryKey,
                        entry.displayValue,
                        '${entry.pointValue}',
                      ])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(text),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
