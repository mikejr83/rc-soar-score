import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/reports/pilot_cards/card_sheet_decision.dart';
import '../../../services/reports/pilot_cards/pilot_cards_options.dart';
import '../../../services/reports/viewer/report_spec.dart';
import '../viewer/report_controls.dart';
import '../viewer/report_definition.dart';
import 'pilot_picker.dart';

/// The panel groups of the Pilot Scoring Cards: Filter (the round range,
/// retired pilots and the pilots), Options (Pre-fill) and Cards (how many to a
/// page, and what the choices produce).
///
/// Unlike the Draw Matrix there is no Compact mode or extra columns: a card
/// always carries the same identity and table. The paper is the viewer's Page
/// group; the orientation is fixed.
List<ReportControlGroup> pilotCardsControls(
  ReportControlsContext context,
  PilotCardsOptions options,
  CardSheetDecision decision,
) {
  final l10n = context.l10n;
  final range = options.range;
  final check = context.check;
  final rangeProblem =
      check is ReportInvalid ||
      (check is ReportEmpty && options.rounds.isEmpty);
  final rounds = {
    for (var r = 1; r <= range.planned; r++)
      '$r': r > range.drawn
          ? l10n.matrixRoundLabelNotDrawn(r)
          : l10n.matrixRoundLabel(r),
  };
  final undrawn = {for (var r = range.drawn + 1; r <= range.planned; r++) '$r'};
  final retired = context.facts.pilots.where((p) => p.isRetired).length;
  final cards = options.selected.length;
  final pages = decision.perPage == null
      ? 0
      : (cards / decision.perPage!.count).ceil();

  return [
    ReportControlGroup(
      title: l10n.standingsFilter,
      children: [
        ReportDropdown(
          label: l10n.standingsFromRound,
          value: '${range.from}',
          items: rounds,
          disabled: undrawn,
          onChanged: (value) => context.setFilter('from', value),
          errorText: rangeProblem ? '' : null,
        ),
        ReportDropdown(
          label: l10n.standingsToRound,
          value: '${range.requestedTo}',
          items: rounds,
          disabled: undrawn,
          onChanged: (value) => context.setFilter('to', value),
          errorText: rangeProblem ? '' : null,
        ),
        ReportFieldMessage(
          key: const ValueKey('cards-range-message'),
          text: switch (check) {
            ReportInvalid(:final message) => message,
            ReportEmpty(:final body) when options.rounds.isEmpty => body,
            _ => range.rangeMessage,
          },
          isError: rangeProblem,
        ),
        if (!range.isAll)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('cards-show-all'),
              onPressed: () =>
                  context.setFilters({'from': '1', 'to': '${range.drawn}'}),
              child: Text(
                range.hasUndrawn
                    ? l10n.matrixShowAllDrawn
                    : l10n.matrixShowAllRounds,
              ),
            ),
          ),
        if (retired > 0)
          ReportCheckOption(
            key: const ValueKey('cards-include-retired'),
            label: l10n.cardsIncludeRetired,
            help: options.includeRetired
                ? l10n.cardsIncludeRetiredHelp
                : l10n.cardsRetiredLeftOut(retired),
            value: options.includeRetired,
            onChanged: (on) => context.setFilter('ret', on ? '1' : '0'),
          ),
        PilotPicker(
          options: options,
          onChanged: (value) => context.setFilters({'pilots': value ?? 'all'}),
        ),
      ],
    ),
    ReportControlGroup(
      title: l10n.cardsOptions,
      children: [
        ReportSwitchOption(
          label: l10n.cardsPrefill,
          help: !options.prefillAvailable
              ? l10n.cardsPrefillUnavailable
              : l10n.cardsPrefillHelp,
          value: options.prefill,
          enabled: options.prefillAvailable,
          onChanged: (on) => context.setFilter('pre', on ? '1' : '0'),
        ),
      ],
    ),
    ReportControlGroup(
      title: l10n.cardsGroup,
      children: [
        RadioGroup<String>(
          groupValue: options.perPage.key,
          onChanged: (key) {
            if (key != null) {
              context.setFilter('up', key);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final choice in CardsPerPageChoice.values)
                RadioListTile<String>(
                  key: ValueKey('cards-up-${choice.key}'),
                  value: choice.key,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  enabled:
                      choice != CardsPerPageChoice.four || decision.fitsFour,
                  title: Text(choice.label(l10n)),
                  subtitle: Text(_choiceHelp(l10n, choice, decision)),
                ),
            ],
          ),
        ),
        ReportFieldMessage(
          key: const ValueKey('cards-up-message'),
          text: decision.message(l10n),
          isError: decision.tooMany,
        ),
        const Divider(),
        RadioGroup<String>(
          groupValue: options.margin.key,
          onChanged: (key) {
            if (key != null) {
              context.setFilter('mg', key);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final margin in PrintMargin.values)
                RadioListTile<String>(
                  key: ValueKey('cards-margin-${margin.key}'),
                  value: margin.key,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.cardsMarginLabel(margin.label(l10n))),
                  subtitle: Text(margin.help(l10n)),
                ),
            ],
          ),
        ),
        Semantics(
          liveRegion: true,
          child: Builder(
            builder: (context) => Text(
              cards == 0 || decision.perPage == null
                  ? l10n.cardsNoCards
                  : l10n.cardsSummary(cards, pages),
              key: const ValueKey('cards-summary'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ],
    ),
  ];
}

String _choiceHelp(
  AppLocalizations l10n,
  CardsPerPageChoice choice,
  CardSheetDecision decision,
) => switch (choice) {
  CardsPerPageChoice.automatic =>
    decision.tooMany
        ? l10n.cardsTooManyRounds
        : decision.perPage?.count == 4
        ? l10n.cardsUsingFourPerPage
        : l10n.cardsUsingTwoPerPage,
  CardsPerPageChoice.four =>
    decision.fitsFour ? l10n.cardsQuarterPage : l10n.cardsRowsUnderEight,
  CardsPerPageChoice.two => l10n.cardsHalfPage,
};
