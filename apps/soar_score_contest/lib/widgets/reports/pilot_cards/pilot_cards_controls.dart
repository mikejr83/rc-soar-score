import 'package:flutter/material.dart';

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
  final range = options.range;
  final check = context.check;
  final rangeProblem =
      check is ReportInvalid ||
      (check is ReportEmpty && options.rounds.isEmpty);
  final rounds = {
    for (var r = 1; r <= range.planned; r++)
      '$r': r > range.drawn ? 'Round $r · not drawn' : 'Round $r',
  };
  final undrawn = {for (var r = range.drawn + 1; r <= range.planned; r++) '$r'};
  final retired = context.facts.pilots.where((p) => p.isRetired).length;
  final cards = options.selected.length;
  final pages = decision.perPage == null
      ? 0
      : (cards / decision.perPage!.count).ceil();

  return [
    ReportControlGroup(
      title: 'Filter',
      children: [
        ReportDropdown(
          label: 'From round',
          value: '${range.from}',
          items: rounds,
          disabled: undrawn,
          onChanged: (value) => context.setFilter('from', value),
          errorText: rangeProblem ? '' : null,
        ),
        ReportDropdown(
          label: 'To round',
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
                range.hasUndrawn ? 'Show all drawn rounds' : 'Show all rounds',
              ),
            ),
          ),
        if (retired > 0)
          ReportCheckOption(
            key: const ValueKey('cards-include-retired'),
            label: 'Include retired pilots',
            help: options.includeRetired
                ? 'Retired pilots are marked “Retired” on their cards.'
                : '$retired retired ${retired == 1 ? 'pilot is' : 'pilots are'} '
                      'left out.',
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
      title: 'Options',
      children: [
        ReportSwitchOption(
          label: 'Pre-fill',
          help: !options.prefillAvailable
              ? 'No scores have been entered yet.'
              : 'Prints the scores already entered, so pilots can check them.',
          value: options.prefill,
          enabled: options.prefillAvailable,
          onChanged: (on) => context.setFilter('pre', on ? '1' : '0'),
        ),
      ],
    ),
    ReportControlGroup(
      title: 'Cards',
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
                  title: Text(choice.label),
                  subtitle: Text(_choiceHelp(choice, decision)),
                ),
            ],
          ),
        ),
        ReportFieldMessage(
          key: const ValueKey('cards-up-message'),
          text: decision.message,
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
                  title: Text('${margin.label} margin'),
                  subtitle: Text(margin.help),
                ),
            ],
          ),
        ),
        Semantics(
          liveRegion: true,
          child: Builder(
            builder: (context) => Text(
              cards == 0 || decision.perPage == null
                  ? 'No cards'
                  : '$cards ${cards == 1 ? 'card' : 'cards'} · $pages '
                        '${pages == 1 ? 'page' : 'pages'}',
              key: const ValueKey('cards-summary'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ],
    ),
  ];
}

String _choiceHelp(CardsPerPageChoice choice, CardSheetDecision decision) =>
    switch (choice) {
      CardsPerPageChoice.automatic =>
        decision.tooMany
            ? 'Too many rounds'
            : decision.perPage?.count == 4
            ? 'Using four per page'
            : 'Using two per page',
      CardsPerPageChoice.four =>
        decision.fitsFour ? 'Quarter-page cards' : 'Rows would be under 8 mm',
      CardsPerPageChoice.two => 'Half-page cards',
    };
