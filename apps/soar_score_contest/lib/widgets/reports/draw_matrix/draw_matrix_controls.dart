import 'package:flutter/material.dart';

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
  final check = context.check;
  final problem = check is ReportInvalid || check is ReportEmpty;
  final rounds = {
    for (var r = 1; r <= options.planned; r++)
      '$r': r > options.drawn ? 'Round $r · not drawn' : 'Round $r',
  };
  final undrawn = {
    for (var r = options.drawn + 1; r <= options.planned; r++) '$r',
  };
  void toggle(String key, bool value) =>
      context.setFilter(key, value ? '1' : '0');

  return [
    ReportControlGroup(
      title: 'Filter',
      children: [
        ReportDropdown(
          label: 'From round',
          value: '${options.from}',
          items: rounds,
          disabled: undrawn,
          onChanged: (value) => context.setFilter('from', value),
          errorText: problem ? '' : null,
        ),
        ReportDropdown(
          label: 'To round',
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
                    ? 'Show all drawn rounds'
                    : 'Show all rounds',
              ),
            ),
          ),
      ],
    ),
    ReportControlGroup(
      title: 'Options',
      children: [
        ReportSwitchOption(
          label: 'Compact mode',
          help: 'Two columns per page, 9 pt text',
          value: options.compact,
          onChanged: (v) => toggle('cmp', v),
        ),
        ReportSwitchOption(
          label: 'Additional pilot info',
          help: !options.additionalAvailable
              ? 'Not available in compact mode'
              : options.additionalChosen
              ? 'Adds a column for each item you tick'
              : 'Club, FAI ID and National ID columns',
          value: options.additionalChosen,
          enabled: options.additionalAvailable,
          onChanged: (v) => toggle('inf', v),
        ),
        if (options.additionalChosen) ...[
          ReportCheckOption(
            label: 'Club',
            value: options.club,
            enabled: options.additionalAvailable,
            onChanged: (v) => toggle('club', v),
          ),
          ReportCheckOption(
            label: 'FAI ID',
            value: options.fai,
            enabled: options.additionalAvailable,
            onChanged: (v) => toggle('fai', v),
          ),
          ReportCheckOption(
            label: 'National ID',
            value: options.national,
            enabled: options.additionalAvailable,
            onChanged: (v) => toggle('nat', v),
          ),
          if (!options.additionalAvailable)
            const ReportFieldMessage(
              text: 'Kept as set. They apply again when Compact mode is off.',
            ),
        ],
      ],
    ),
    if (context.facts.teamsEnabled ||
        context.facts.numbersEnabled ||
        context.facts.classesEnabled)
      ReportControlGroup(
        title: 'Columns',
        children: [
          if (context.facts.teamsEnabled)
            ReportCheckOption(
              label: 'Team',
              value: options.teamChosen,
              onChanged: (v) => toggle('team', v),
            ),
          if (context.facts.numbersEnabled)
            ReportCheckOption(
              label: 'Pilot number',
              value: options.numberChosen,
              onChanged: (v) => toggle('num', v),
            ),
          if (context.facts.classesEnabled)
            ReportCheckOption(
              label: 'Pilot class',
              value: options.classChosen,
              onChanged: (v) => toggle('cls', v),
            ),
        ],
      ),
  ];
}
