import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../collapsible_areas_provider.dart';
import '../../services/collapsible_areas/collapsible_area.dart';
import '../../services/configuration/configuration_data.dart';
import '../../services/configuration/configuration_draft.dart';
import '../../services/configuration/setting_keys.dart';
import '../landings/landing_unit_text.dart';
import 'config_chip.dart';
import 'config_note.dart';
import 'field_registry.dart';
import 'fixed_chip.dart';
import 'landing_entries_table.dart';
import 'landing_picker_dialog.dart';

/// The body of the landing table section: the table in use, its facts, the
/// button to change it and the entries.
class LandingSectionBody extends StatefulWidget {
  const LandingSectionBody({
    super.key,
    required this.data,
    required this.draft,
    required this.registry,
    required this.editable,
    required this.onChanged,
    required this.onOpenLandings,
  });

  final ConfigurationData data;
  final ConfigurationDraft draft;
  final FieldRegistry registry;
  final bool editable;
  final VoidCallback onChanged;
  final VoidCallback onOpenLandings;

  @override
  State<LandingSectionBody> createState() => _LandingSectionBodyState();
}

class _LandingSectionBodyState extends State<LandingSectionBody> {
  /// Whether the entries table is shown, remembered per account
  /// ([landingEntriesArea]).
  bool? _localEntries;
  bool _showEntries() {
    final areas = collapsibleAreasOf(context);
    return areas == null
        ? _localEntries ?? false
        : areas.isOpen(landingEntriesArea);
  }

  void _toggleEntries() {
    final areas = collapsibleAreasOf(context);
    if (areas == null) {
      setState(() => _localEntries = !_showEntries());
      return;
    }
    unawaited(areas.setOpen(landingEntriesArea, !_showEntries()));
  }

  ConfigurationDraft get _draft => widget.draft;

  Id? _tableId(Object? value) => value == null ? null : Id.parse('$value');

  Future<void> _choose() async {
    final picked = await showDialog<Id>(
      context: context,
      builder: (context) => LandingPickerDialog(
        tables: widget.data.landingTables,
        current: _tableId(_draft[SettingKeys.landingTable]),
        defaultTableId: widget.data.profile?.profile.defaultLandingTableId,
        defaultLabel: _draft.catalog.defaultLabel,
        onCreateTable: widget.onOpenLandings,
      ),
    );
    if (picked != null) {
      _draft.set(SettingKeys.landingTable, picked.value);
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final scheme = theme.colorScheme;
    final def = _draft.catalog.byKey[SettingKeys.landingTable]!;
    final effect = _draft.effectOf(def);
    final fixed = !widget.editable || effect.fixed;
    final view = widget.data.landingTable(
      _tableId(_draft[SettingKeys.landingTable]),
    );
    final change = _draft.changeOf(SettingKeys.landingTable);
    final error = _draft.errors[SettingKeys.landingTable];
    final showEntries = _showEntries();
    final defaultId = widget.data.profile?.profile.defaultLandingTableId;
    final defaultView = widget.data.landingTable(defaultId);
    final savedView = widget.data.landingTable(
      _tableId(_draft.saved[SettingKeys.landingTable]),
    );

    return KeyedSubtree(
      key: widget.registry.rowKey(SettingKeys.landingTable),
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: 16),
            if (view != null)
              _currentCard(
                context,
                view,
                change != null,
                widget.editable && effect.fixed ? effect.reason : null,
                defaultId,
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.error),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: scheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.configLandingNoTable,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  focusNode: widget.registry.focusNode(
                    SettingKeys.landingTable,
                  ),
                  onPressed: fixed ? null : _choose,
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(
                    view == null
                        ? l10n.configLandingChoose
                        : l10n.configLandingChange,
                  ),
                ),
                if (view != null)
                  OutlinedButton.icon(
                    key: const ValueKey('landing-entries-toggle'),
                    onPressed: _toggleEntries,
                    icon: Icon(
                      showEntries ? Icons.expand_less : Icons.expand_more,
                    ),
                    label: Text(
                      showEntries
                          ? l10n.configLandingHideEntries
                          : l10n.configLandingShowEntries,
                    ),
                  ),
                TextButton.icon(
                  onPressed: widget.onOpenLandings,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(l10n.configOpenLandings),
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              ConfigNote(
                noteId: const ValueKey('error-${SettingKeys.landingTable}'),
                icon: Icons.error_outline,
                text: error,
                tone: ConfigNoteTone.error,
              ),
            ],
            if (view != null &&
                defaultView != null &&
                view.table.id != defaultId) ...[
              const SizedBox(height: 12),
              ConfigNote(
                icon: Icons.info_outline,
                text: l10n.configLandingNotDefault(
                  _draft.catalog.defaultLabel,
                  defaultView.table.name,
                  landingUnitLabel(l10n, view.table.inputUnit).toLowerCase(),
                ),
              ),
            ],
            if (change != null) ...[
              const SizedBox(height: 12),
              ConfigNote(
                icon: Icons.history,
                text: l10n.configLandingSaved(
                  savedView?.table.name ?? l10n.configLandingNone,
                ),
                actionLabel: l10n.commonUndo,
                actionIcon: Icons.undo,
                onAction: () {
                  _draft.set(
                    SettingKeys.landingTable,
                    _draft.saved[SettingKeys.landingTable],
                  );
                  widget.onChanged();
                },
              ),
              if (change.effect.outdatesMatrix) ...[
                const SizedBox(height: 8),
                ConfigNote(
                  icon: Icons.sync_problem,
                  text: l10n.configLandingOutdatesMatrix,
                  tone: ConfigNoteTone.warning,
                ),
              ],
            ],
            if (view != null && showEntries) ...[
              const SizedBox(height: 12),
              LandingEntriesTable(view: view),
            ],
          ],
        ),
      ),
    );
  }

  Widget _currentCard(
    BuildContext context,
    LandingTableView view,
    bool changed,
    String? fixedReason,
    Id? defaultId,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final scheme = theme.colorScheme;
    final meta = [
      (l10n.configLandingUnit, landingUnitLabel(l10n, view.table.inputUnit)),
      (l10n.configLandingEntries, '${view.results.length}'),
      (
        l10n.configLandingPointsRange,
        LandingEntriesTable.pointsRange(l10n, view),
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Icon(Icons.table_rows_outlined, color: scheme.primary),
              Text(view.table.name, style: theme.textTheme.titleMedium),
              if (view.table.id == defaultId)
                ConfigChip.neutral(
                  context,
                  icon: Icons.verified_outlined,
                  text: widget.draft.catalog.defaultLabel,
                ),
              if (changed) ConfigChip.unsaved(context),
              if (fixedReason != null) FixedChip(reason: fixedReason),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 32,
            runSpacing: 12,
            children: [
              for (final (label, value) in meta)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(value, style: theme.textTheme.bodyLarge),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
