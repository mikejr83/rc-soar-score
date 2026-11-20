import 'package:material_ui/material_ui.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';

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
  String? lockedReason(AppLocalizations l10n) => view.table.isSystem
      ? l10n.landingsLockedSystem
      : view.inUse
          ? l10n.landingsLockedInUse
          : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locked = lockedReason(l10n);
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
                tooltip: l10n.landingsBackToLandings,
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(view.table.name, style: theme.textTheme.headlineSmall),
                  Text(
                    '${landingUnitLabel(l10n, view.table.inputUnit)} · '
                    '${l10n.landingsEntries(view.results.length)}',
                    style: muted,
                  ),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              key: const ValueKey('copy-landing'),
              onPressed: onCopy,
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: Text(l10n.landingsCreateCopy),
            ),
            if (locked == null)
              IconButton(
                key: const ValueKey('delete-landing'),
                tooltip: l10n.landingsDeleteTooltip(view.table.name),
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
                    child: Text(l10n.landingsLockedNote(locked)),
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
              columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth()},
              children: [
                TableRow(
                  children: [
                    for (final heading in [
                      l10n.landingsLabelHeading,
                      l10n.landingsPointsHeading,
                    ])
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
