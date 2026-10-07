import 'package:flutter/material.dart';

import '../../services/new_contest/contest_draft.dart';
import '../../services/new_contest/copy_mode.dart';

/// What will be copied from the source contest, and what never is.
class CopySummary extends StatelessWidget {
  const CopySummary({super.key, required this.draft});

  final ContestDraft draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final source = draft.source!;
    final mode = draft.copyMode;
    final total = source.pilots.length;
    final rows = <(String, String)>[
      ('Source', source.contest.name),
      ('Copies', mode.label),
      (
        'Pilots',
        switch (mode) {
          CopyMode.selectedPilots => '${draft.participants.length} selected',
          CopyMode.allPilots => 'All $total',
          _ => 'None',
        },
      ),
      if (mode.copiesPilots) ('Per pilot', 'Participation and class'),
      (
        'Not copied',
        'Teams, models, non-flying participants, scores, matrix, publication '
            'history, invitations, audit history',
      ),
    ];
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Semantics(
      container: true,
      label: 'Copy summary',
      child: Container(
        key: const ValueKey('copy-summary'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COPY SUMMARY',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: FlexColumnWidth(),
              },
              children: [
                for (final (label, value) in rows)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 20, bottom: 6),
                        child: Text(label, style: labelStyle),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(value, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
