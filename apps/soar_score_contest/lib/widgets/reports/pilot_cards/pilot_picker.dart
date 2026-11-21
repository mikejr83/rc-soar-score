import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/app_localizations_en.dart';
import '../../../services/reports/pilot_cards/pilot_cards_options.dart';
import '../../../services/reports/report_pilot.dart';

final AppLocalizations _fallbackL10n = AppLocalizationsEn();

AppLocalizations _l10nOf(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    _fallbackL10n;

/// The pilots that get a card: a searchable checkbox list with Select all,
/// Select none, a team shortcut and a live count. With a search active the
/// buttons act on the matches only and say so.
///
/// Lists use "Surname, Given"; the cards use "Given Surname". There is no
/// "select by group": groups change every round, so a group is not a stable
/// set of pilots.
class PilotPicker extends StatefulWidget {
  const PilotPicker({
    super.key,
    required this.options,
    required this.onChanged,
    this.listHeight = 244,
  });

  final PilotCardsOptions options;

  /// Told the new `pilots` filter value: `null` for everyone.
  final ValueChanged<String?> onChanged;
  final double listHeight;

  @override
  State<PilotPicker> createState() => _PilotPickerState();
}

class _PilotPickerState extends State<PilotPicker> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  PilotCardsOptions get _options => widget.options;

  Set<String> get _chosen => {
    for (final pilot in _options.selected) pilot.participationId.value,
  };

  List<ReportPilot> get _shown {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _options.eligible;
    }
    return [
      for (final pilot in _options.eligible)
        if ('${pilot.listName} ${pilot.givenSurname} ${pilot.team ?? ''} '
                '${pilot.club ?? ''}'
            .toLowerCase()
            .contains(query))
          pilot,
    ];
  }

  void _set(Set<String> ids) => widget.onChanged(_options.pilotsValue(ids));

  void _toggle(ReportPilot pilot, bool on) {
    final ids = _chosen;
    final id = pilot.participationId.value;
    on ? ids.add(id) : ids.remove(id);
    _set(ids);
  }

  void _selectShown() => _set({
    ..._chosen,
    for (final pilot in _shown) pilot.participationId.value,
  });

  void _deselectShown() => _set({
    ..._chosen.difference({
      for (final pilot in _shown) pilot.participationId.value,
    }),
  });

  void _addTeam(String team) => _set({
    ..._chosen,
    for (final pilot in _options.eligible)
      if (pilot.team == team) pilot.participationId.value,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = _l10nOf(context);
    final theme = Theme.of(context);
    final shown = _shown;
    final searching = _search.text.trim().isNotEmpty;
    final total = _options.eligible.length;
    final count = _options.selected.length;
    final teams = {for (final pilot in _options.eligible) ?pilot.team}.toList()
      ..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.cardsPilotsHeading,
                style: theme.textTheme.titleSmall,
              ),
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.cardsPilotCount(count, total),
                key: const ValueKey('cards-pilot-count'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: count == 0
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        SearchBar(
          key: const ValueKey('cards-pilot-search'),
          controller: _search,
          hintText: l10n.cardsSearchPilots,
          leading: const Icon(Icons.search),
          elevation: const WidgetStatePropertyAll(0),
          constraints: const BoxConstraints(minHeight: 44, maxHeight: 44),
          onChanged: (_) => setState(() {}),
        ),
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              key: const ValueKey('cards-select-all'),
              onPressed: shown.isEmpty ? null : _selectShown,
              child: Text(
                searching
                    ? l10n.cardsSelectShown(shown.length)
                    : l10n.cardsSelectAll,
              ),
            ),
            TextButton(
              key: const ValueKey('cards-select-none'),
              onPressed: shown.isEmpty ? null : _deselectShown,
              child: Text(
                searching ? l10n.cardsClearShown : l10n.cardsSelectNone,
              ),
            ),
            if (teams.isNotEmpty)
              PopupMenuButton<String>(
                key: const ValueKey('cards-add-team'),
                tooltip: l10n.cardsAddTeamHint,
                onSelected: _addTeam,
                itemBuilder: (context) => [
                  for (final team in teams)
                    PopupMenuItem(value: team, child: Text(team)),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.cardsAddTeam),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
          ],
        ),
        Semantics(
          container: true,
          label: l10n.cardsPilotList,
          child: Container(
            height: widget.listHeight,
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: shown.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      total == 0
                          ? l10n.cardsNoPilotsYet
                          : l10n.cardsNoPilotMatches(_search.text.trim()),
                      style: theme.textTheme.bodySmall,
                    ),
                  )
                : ListView.builder(
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final pilot = shown[i];
                      return CheckboxListTile(
                        key: ValueKey('cards-pilot-${pilot.participationId}'),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _options.isSelected(pilot),
                        onChanged: (on) => _toggle(pilot, on ?? false),
                        title: Text(pilot.listName),
                        subtitle: _sub(pilot) == null
                            ? null
                            : Text(_sub(pilot)!),
                        secondary: pilot.isRetired
                            ? Text(
                                l10n.cardsRetired,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  String? _sub(ReportPilot pilot) {
    final parts = [
      if (pilot.team != null) pilot.team!,
      if (pilot.className != null) pilot.className!,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
