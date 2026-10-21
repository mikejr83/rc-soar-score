import 'package:flutter/material.dart';

import '../../../services/reports/reports_facts.dart';
import '../../../services/reports/standings/standings_options.dart';
import '../../../services/reports/viewer/report_spec.dart';
import '../viewer/report_controls.dart';
import '../viewer/report_definition.dart';

/// The Overall Standings panel groups: Filter (the round range), Options (the
/// optional columns) and Detail (flight details and provisional). Options the
/// contest does not use (team, pilot number, class) are left out, because
/// there is nothing to explain.
List<ReportControlGroup> standingsControls(
  ReportControlsContext context,
  StandingsOptions options,
) {
  final facts = context.facts;
  final check = context.check;
  final rounds = {
    for (var r = 1; r <= facts.lastScoredRound; r++)
      '$r': _roundLabel(facts, r),
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
          onChanged: (value) => context.setFilter('from', value),
          errorText: check is ReportInvalid ? '' : null,
        ),
        ReportDropdown(
          label: 'To round',
          value: '${options.requestedTo}',
          items: rounds,
          onChanged: (value) => context.setFilter('to', value),
          errorText: check is ReportInvalid ? '' : null,
        ),
        ReportFieldMessage(
          key: const ValueKey('standings-range-message'),
          text: check is ReportInvalid
              ? check.message
              : options.to < 1
              ? 'No rounds can be shown yet.'
              : 'Rank and total are the standings as of round ${options.to}. '
                    'Only rounds with scores are listed.',
          isError: check is ReportInvalid,
        ),
      ],
    ),
    ReportControlGroup(
      title: 'Options',
      children: [
        ReportCheckOption(
          label: 'Percentage of total',
          help: 'Each total as a percentage of the winner’s',
          value: options.percentage,
          onChanged: (v) => toggle('pct', v),
        ),
        ReportCheckOption(
          label: 'Raw score',
          help: 'Total plus the dropped rounds. Not the score of each round.',
          value: options.raw,
          onChanged: (v) => toggle('raw', v),
        ),
        if (facts.teamsEnabled)
          ReportCheckOption(
            label: 'Team',
            value: options.team,
            onChanged: (v) => toggle('team', v),
          ),
        if (facts.numbersEnabled)
          ReportCheckOption(
            label: 'Pilot number',
            value: options.number,
            onChanged: (v) => toggle('num', v),
          ),
        if (facts.classesEnabled)
          ReportCheckOption(
            label: 'Pilot class',
            value: options.pilotClass,
            onChanged: (v) => toggle('cls', v),
          ),
      ],
    ),
    ReportControlGroup(
      title: 'Detail',
      children: [
        ReportCheckOption(
          label: 'Flight details',
          help: facts.disciplineLabel == 'F3J'
              ? 'Adds flight time and landing points under each round score.'
              : 'Adds flight time, landing points and launch height under '
                    'each round score.',
          value: options.details,
          onChanged: (v) => toggle('det', v),
        ),
        if (StandingsOptions.provisionalApplies(facts))
          ReportCheckOption(
            label: 'Provisional',
            help: _provisionalHelp(facts, options),
            value: options.provisional,
            onChanged: (v) => toggle('prov', v),
          ),
      ],
    ),
  ];
}

String _roundLabel(ReportsFacts facts, int round) {
  final fact = facts.roundFact(round);
  final partly = fact != null && fact.scored > 0 && fact.scored < fact.total;
  return partly ? 'Round $round (partly scored)' : 'Round $round';
}

String _provisionalHelp(ReportsFacts facts, StandingsOptions options) {
  final partial = facts.rounds
      .where((r) => r.scored > 0 && r.scored < r.total)
      .map((r) => r.ordinal)
      .firstOrNull;
  if (options.provisional) {
    return partial == null
        ? 'Shows rounds up to the last with any score.'
        : 'Round $partial is partly scored, so this is on. Shows rounds up to '
              'the last with any score.';
  }
  final full = facts.lastFullyScoredRound;
  return full == 0
      ? 'No round is fully scored yet.'
      : 'Only fully scored rounds (1 to $full) are shown.';
}
