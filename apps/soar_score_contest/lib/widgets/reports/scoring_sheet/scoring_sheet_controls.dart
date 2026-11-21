import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
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
  final l10n = context.l10n;
  final range = options.range;
  final check = context.check;
  final problem =
      check is ReportInvalid ||
      (check is ReportEmpty && options.rounds.isEmpty);
  final rounds = {
    for (var r = 1; r <= range.planned; r++)
      '$r': r > range.drawn
          ? l10n.matrixRoundLabelNotDrawn(r)
          : l10n.matrixRoundLabel(r),
  };
  final undrawn = {for (var r = range.drawn + 1; r <= range.planned; r++) '$r'};
  void toggle(String key, bool value) =>
      context.setFilter(key, value ? '1' : '0');

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
          errorText: problem ? '' : null,
        ),
        ReportDropdown(
          label: l10n.standingsToRound,
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
                range.hasUndrawn
                    ? l10n.matrixShowAllDrawn
                    : l10n.matrixShowAllRounds,
              ),
            ),
          ),
        if (options.retiredCount > 0)
          ReportCheckOption(
            key: const ValueKey('sheet-include-retired'),
            label: l10n.cardsIncludeRetired,
            help: options.includeRetired
                ? l10n.sheetIncludeRetiredHelp
                : l10n.sheetRetiredLeftOut(options.retiredCount),
            value: options.includeRetired,
            onChanged: (on) => toggle('ret', on),
          ),
      ],
    ),
    ReportControlGroup(
      title: l10n.standingsOptions,
      children: [
        if (columns != null) _readout(l10n, columns, bodyWidth),
        ReportSwitchOption(
          key: const ValueKey('sheet-prefill'),
          label: l10n.cardsPrefill,
          help: !options.prefillAvailable
              ? l10n.cardsPrefillUnavailable
              : options.prefill
              ? l10n.sheetPrefillOn
              : l10n.sheetPrefillOff,
          value: options.prefill,
          enabled: options.prefillAvailable,
          onChanged: (on) => toggle('pre', on),
        ),
        ReportCheckOption(
          key: const ValueKey('sheet-club'),
          label: l10n.matrixClub,
          help: l10n.sheetClubHelp,
          value: options.clubChosen,
          onChanged: (on) => toggle('club', on),
        ),
        if (options.teamsEnabled)
          ReportCheckOption(
            key: const ValueKey('sheet-team'),
            label: l10n.standingsTeam,
            value: options.teamChosen,
            onChanged: (on) => toggle('team', on),
          ),
        if (options.numbersEnabled)
          ReportCheckOption(
            key: const ValueKey('sheet-number'),
            label: l10n.standingsPilotNumber,
            value: options.numberChosen,
            onChanged: (on) => toggle('num', on),
          ),
        if (options.classesEnabled)
          ReportCheckOption(
            key: const ValueKey('sheet-class'),
            label: l10n.standingsPilotClass,
            value: options.classChosen,
            onChanged: (on) => toggle('cls', on),
          ),
        ReportCheckOption(
          key: const ValueKey('sheet-validated'),
          label: l10n.sheetValidated,
          help: l10n.sheetValidatedHelp,
          value: options.validated,
          onChanged: (on) => toggle('val', on),
        ),
      ],
    ),
  ];
}

/// What the columns do on the page: the writing width, or that they continue.
Widget _readout(
  AppLocalizations l10n,
  List<ScoringSheetColumn> columns,
  double bodyWidth,
) {
  final strips = ScoringSheetColumns.plan(columns, bodyWidth);
  final across = (bodyWidth / ScoringSheetColumns.pxPerMm).round();
  final text = strips.length == 1
      ? l10n.sheetWritingCells(
          ScoringSheetColumns.writingMm(strips).round(),
          across,
        )
      : l10n.sheetColumnsContinue(across, strips.length - 1);
  return ReportFieldMessage(
    key: const ValueKey('sheet-readout'),
    text: text,
    isError: false,
  );
}
