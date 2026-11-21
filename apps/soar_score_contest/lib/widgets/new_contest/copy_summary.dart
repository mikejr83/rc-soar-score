import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../services/new_contest/contest_draft.dart';
import '../../services/new_contest/copy_mode.dart';

/// What will be copied from the source contest, and what never is.
class CopySummary extends StatelessWidget {
  const CopySummary({super.key, required this.draft});

  final ContestDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final source = draft.source!;
    final mode = draft.copyMode;
    final total = source.pilots.length;
    final rows = <(String, String)>[
      (l10n.wizardCopySourceLabel, source.contest.name),
      (l10n.wizardCopyCopiesLabel, mode.label(l10n)),
      (
        l10n.wizardCopyPilotsLabel,
        switch (mode) {
          CopyMode.selectedPilots => '${draft.participants.length} selected',
          CopyMode.allPilots => l10n.wizardCopyAllPilots(total),
          _ => l10n.wizardCopyNone,
        },
      ),
      if (mode.copiesPilots)
        (l10n.wizardCopyPerPilot, l10n.wizardCopyPerPilotValue),
      (l10n.wizardCopyNotCopied, l10n.wizardCopyNotCopiedValue),
    ];
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Semantics(
      container: true,
      label: l10n.wizardCopySummaryLabel,
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
              l10n.wizardCopySummaryTitle,
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
