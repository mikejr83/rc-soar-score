import 'package:material_ui/material_ui.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'choice_card.dart';
import 'config_chip.dart';
import 'landing_entries_table.dart';

/// Chooses the contest's landing table from the system tables and the
/// director's own, with a preview of the highlighted one. Closes with the
/// chosen table's id, or `null` when cancelled.
class LandingPickerDialog extends StatefulWidget {
  const LandingPickerDialog({
    super.key,
    required this.tables,
    required this.current,
    required this.defaultTableId,
    required this.defaultLabel,
    required this.onCreateTable,
  });

  final List<LandingTableView> tables;

  /// The table the draft uses now, marked `Current`.
  final Id? current;

  /// The profile's default table, marked as the default.
  final Id? defaultTableId;

  /// What the default table is called, for example `F5J default`.
  final String defaultLabel;

  /// Opens the Landings page to create a table.
  final VoidCallback onCreateTable;

  @override
  State<LandingPickerDialog> createState() => _LandingPickerDialogState();
}

class _LandingPickerDialogState extends State<LandingPickerDialog> {
  late Id? _picked =
      widget.current ??
      widget.defaultTableId ??
      widget.tables.firstOrNull?.table.id;

  LandingTableView? get _pickedView =>
      widget.tables.where((v) => v.table.id == _picked).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final scheme = theme.colorScheme;
    final view = _pickedView;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.landingPickerTitle,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.landingPickerNote,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 280,
                        maxWidth: 400,
                      ),
                      child: RadioGroup<Id>(
                        groupValue: _picked,
                        onChanged: (id) => setState(() => _picked = id),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Column(
                                children: [
                                  for (final view in widget.tables) _item(l10n, view),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (view != null)
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 260,
                          maxWidth: 420,
                        ),
                        child: _preview(l10n, theme, view),
                      ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: widget.onCreateTable,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.landingPickerCreateTable),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.cancelButton),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _picked == null
                            ? null
                            : () => Navigator.of(context).pop(_picked),
                        child: Text(l10n.landingPickerUse),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(AppLocalizations l10n, LandingTableView view) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = view.table.id == _picked;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ChoiceCard(
        selected: selected,
        child: RadioListTile<Id>(
          value: view.table.id,
          dense: true,
          contentPadding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
          title: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(view.table.name),
              if (view.table.id == widget.defaultTableId)
                ConfigChip(
                  icon: Icons.star_outline,
                  text: l10n.landingPickerProfileDefault,
                  background: scheme.secondaryContainer,
                  foreground: scheme.onSecondaryContainer,
                ),
              if (view.table.id == widget.current)
                ConfigChip.neutral(
                  context,
                  icon: Icons.check,
                  text: l10n.landingPickerCurrent,
                ),
            ],
          ),
          subtitle: Text(LandingEntriesTable.summary(l10n, view)),
        ),
      ),
    );
  }

  Widget _preview(AppLocalizations l10n, ThemeData theme, LandingTableView view) {
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Preview',
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(view.table.name, style: theme.textTheme.titleMedium),
        Text(
          LandingEntriesTable.summary(l10n, view),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        LandingEntriesTable(view: view),
      ],
    );
  }
}
