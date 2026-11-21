import 'package:material_ui/material_ui.dart';

import '../../../services/reports/draw_matrix/draw_matrix_options.dart';
import '../../../services/reports/viewer/report_spec.dart';
import '../viewer/report_controls.dart';
import '../viewer/report_definition.dart';

/// The Draw Matrix panel groups: Filter (the round range) and Options (compact
/// mode and additional pilot info). Rounds the contest plans but has not drawn
/// are listed and disabled, so the director sees why the list stops.
List<ReportControlGroup> drawMatrixControls(
  ReportControlsContext context,
  DrawMatrixOptions options,
) {
  final l10n = context.l10n;
  final check = context.check;
  final problem = check is ReportInvalid || check is ReportEmpty;
  final rounds = {
    for (var r = 1; r <= options.planned; r++)
      '$r': r > options.drawn
          ? l10n.matrixRoundLabelNotDrawn(r)
          : l10n.matrixRoundLabel(r),
  };
  final undrawn = {
    for (var r = options.drawn + 1; r <= options.planned; r++) '$r',
  };
  void toggle(String key, bool value) =>
      context.setFilter(key, value ? '1' : '0');

  return [
    ReportControlGroup(
      title: l10n.standingsFilter,
      children: [
        ReportDropdown(
          label: l10n.standingsFromRound,
          value: '${options.from}',
          items: rounds,
          disabled: undrawn,
          onChanged: (value) => context.setFilter('from', value),
          errorText: problem ? '' : null,
        ),
        ReportDropdown(
          label: l10n.standingsToRound,
          value: '${options.requestedTo}',
          items: rounds,
          disabled: undrawn,
          onChanged: (value) => context.setFilter('to', value),
          errorText: problem ? '' : null,
        ),
        ReportFieldMessage(
          key: const ValueKey('matrix-range-message'),
          text: switch (check) {
            ReportInvalid(:final message) => message,
            ReportEmpty(:final body) => body,
            _ => options.rangeMessage,
          },
          isError: problem,
        ),
        if (!options.isAll)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('matrix-show-all'),
              onPressed: () =>
                  context.setFilters({'from': '1', 'to': '${options.drawn}'}),
              child: Text(
                options.hasUndrawn
                    ? l10n.matrixShowAllDrawn
                    : l10n.matrixShowAllRounds,
              ),
            ),
          ),
      ],
    ),
    ReportControlGroup(
      title: l10n.standingsOptions,
      children: [
        ReportSwitchOption(
          label: l10n.matrixCompactMode,
          help: l10n.matrixCompactHelp,
          value: options.compact,
          onChanged: (v) => toggle('cmp', v),
        ),
        ReportSwitchOption(
          label: l10n.matrixAdditionalInfo,
          help: !options.additionalAvailable
              ? l10n.matrixAdditionalUnavailable
              : options.additionalChosen
              ? l10n.matrixAdditionalChosenHelp
              : l10n.matrixAdditionalDefaultHelp,
          value: options.additionalChosen,
          enabled: options.additionalAvailable,
          onChanged: (v) => toggle('inf', v),
        ),
        if (options.additionalChosen) ...[
          ReportCheckOption(
            label: l10n.matrixClub,
            value: options.club,
            enabled: options.additionalAvailable,
            onChanged: (v) => toggle('club', v),
          ),
          ReportCheckOption(
            label: l10n.matrixFaiId,
            value: options.fai,
            enabled: options.additionalAvailable,
            onChanged: (v) => toggle('fai', v),
          ),
          ReportCheckOption(
            label: l10n.matrixNationalId,
            value: options.national,
            enabled: options.additionalAvailable,
            onChanged: (v) => toggle('nat', v),
          ),
          if (!options.additionalAvailable)
            ReportFieldMessage(text: l10n.matrixAdditionalKept),
        ],
      ],
    ),
    if (context.facts.teamsEnabled ||
        context.facts.numbersEnabled ||
        context.facts.classesEnabled)
      ReportControlGroup(
        title: l10n.matrixColumns,
        children: [
          if (context.facts.teamsEnabled)
            ReportCheckOption(
              label: l10n.standingsTeam,
              value: options.teamChosen,
              onChanged: (v) => toggle('team', v),
            ),
          if (context.facts.numbersEnabled)
            ReportCheckOption(
              label: l10n.standingsPilotNumber,
              value: options.numberChosen,
              onChanged: (v) => toggle('num', v),
            ),
          if (context.facts.classesEnabled)
            ReportCheckOption(
              label: l10n.standingsPilotClass,
              value: options.classChosen,
              onChanged: (v) => toggle('cls', v),
            ),
        ],
      ),
  ];
}
