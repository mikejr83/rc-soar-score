import 'package:flutter/material.dart';

import '../../../services/reports/scoring_sheet/scoring_sheet_columns.dart';
import '../../../services/reports/scoring_sheet/scoring_sheet_options.dart';
import '../../../services/reports/viewer/report_spec.dart';
import '../viewer/report_controls.dart';
import '../viewer/report_definition.dart';

/// The Scoring Sheet panel groups: Filter (the round range and retired pilots)
/// and Options (Pre-fill and the columns that can be hidden). [columns] is
/// `null` until the draw is read; [bodyWidth] is the page body in pixels.
List<ReportControlGroup> scoringSheetControls(
  ReportControlsContext context,
  ScoringSheetOptions options,
  List<ScoringSheetColumn>? columns,
  double bodyWidth,
) {
  final range = options.range;
  final check = context.check;
  final problem =
      check is ReportInvalid ||
      (check is ReportEmpty && options.rounds.isEmpty);
  final rounds = {
    for (var r = 1; r <= range.planned; r++)
      '$r': r > range.drawn ? 'Round $r · not drawn' : 'Round $r',
  };
  final undrawn = {for (var r = range.drawn + 1; r <= range.planned; r++) '$r'};
  void toggle(String key, bool value) =>
      context.setFilter(key, value ? '1' : '0');

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
          errorText: problem ? '' : null,
        ),
        ReportDropdown(
          label: 'To round',
          value: '${range.requestedTo}',
          items: rounds,
          disabled: undrawn,
          onChanged: (value) => context.setFilter('to', value),
          errorText: problem ? '' : null,
        ),
        ReportFieldMessage(
          key: const ValueKey('sheet-range-message'),
          text: switch (check) {
            ReportInvalid(:final message) => message,
            ReportEmpty(:final body) when options.rounds.isEmpty => body,
            _ => range.rangeMessage,
          },
          isError: problem,
        ),
        if (!range.isAll)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('sheet-show-all'),
              onPressed: () =>
                  context.setFilters({'from': '1', 'to': '${range.drawn}'}),
              child: Text(
                range.hasUndrawn ? 'Show all drawn rounds' : 'Show all rounds',
              ),
            ),
          ),
        if (options.retiredCount > 0)
          ReportCheckOption(
            key: const ValueKey('sheet-include-retired'),
            label: 'Include retired pilots',
            help: options.includeRetired
                ? 'Retired pilots stay in every round, marked (R).'
                : '${options.retiredCount} retired '
                      '${options.retiredCount == 1 ? 'pilot is' : 'pilots are'} '
                      'left out of the rounds after they retired.',
            value: options.includeRetired,
            onChanged: (on) => toggle('ret', on),
          ),
      ],
    ),
    ReportControlGroup(
      title: 'Options',
      children: [
        if (columns != null) _readout(columns, bodyWidth),
        ReportSwitchOption(
          key: const ValueKey('sheet-prefill'),
          label: 'Pre-fill',
          help: !options.prefillAvailable
              ? 'No scores have been entered yet.'
              : options.prefill
              ? 'Prints the scores already entered. * marks values not yet '
                    'official.'
              : 'Prints the scores already entered, so the sheet can be '
                    'checked against them.',
          value: options.prefill,
          enabled: options.prefillAvailable,
          onChanged: (on) => toggle('pre', on),
        ),
        ReportCheckOption(
          key: const ValueKey('sheet-club'),
          label: 'Club',
          help: 'Off by default. Hidden: its width goes to the writing cells.',
          value: options.clubChosen,
          onChanged: (on) => toggle('club', on),
        ),
        if (options.teamsEnabled)
          ReportCheckOption(
            key: const ValueKey('sheet-team'),
            label: 'Team',
            value: options.teamChosen,
            onChanged: (on) => toggle('team', on),
          ),
        if (options.numbersEnabled)
          ReportCheckOption(
            key: const ValueKey('sheet-number'),
            label: 'Pilot number',
            value: options.numberChosen,
            onChanged: (on) => toggle('num', on),
          ),
        if (options.classesEnabled)
          ReportCheckOption(
            key: const ValueKey('sheet-class'),
            label: 'Pilot class',
            value: options.classChosen,
            onChanged: (on) => toggle('cls', on),
          ),
        ReportCheckOption(
          key: const ValueKey('sheet-validated'),
          label: 'Validated',
          help: 'A blank spot for officials’ initials or notes.',
          value: options.validated,
          onChanged: (on) => toggle('val', on),
        ),
      ],
    ),
  ];
}

/// What the columns do on the page: the writing width, or that they continue.
Widget _readout(List<ScoringSheetColumn> columns, double bodyWidth) {
  final strips = ScoringSheetColumns.plan(columns, bodyWidth);
  final across = (bodyWidth / ScoringSheetColumns.pxPerMm).round();
  final text = strips.length == 1
      ? 'Writing cells ${ScoringSheetColumns.writingMm(strips).round()} mm of '
            '$across mm across the page'
      : 'The columns need more than the $across mm across this page: they '
            'continue on ${strips.length - 1} more '
            '${strips.length == 2 ? 'page' : 'pages'} for the same rows.';
  return ReportFieldMessage(
    key: const ValueKey('sheet-readout'),
    text: text,
    isError: false,
  );
}
