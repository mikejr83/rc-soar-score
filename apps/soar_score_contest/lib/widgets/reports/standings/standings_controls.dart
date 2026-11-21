import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
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
  final l10n = context.l10n;
  final facts = context.facts;
  final check = context.check;
  final rounds = {
    for (var r = 1; r <= facts.defaultStandingsRound; r++)
      '$r': _roundLabel(l10n, facts, r),
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
          onChanged: (value) => context.setFilter('from', value),
          errorText: check is ReportInvalid ? '' : null,
        ),
        ReportDropdown(
          label: l10n.standingsToRound,
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
              ? l10n.standingsNoRounds
              : l10n.standingsRangeText(options.to),
          isError: check is ReportInvalid,
        ),
      ],
    ),
    ReportControlGroup(
      title: l10n.standingsOptions,
      children: [
        ReportCheckOption(
          label: l10n.standingsPercentage,
          help: l10n.standingsPercentageHelp,
          value: options.percentage,
          onChanged: (v) => toggle('pct', v),
        ),
        ReportCheckOption(
          label: l10n.standingsRaw,
          help: l10n.standingsRawHelp,
          value: options.raw,
          onChanged: (v) => toggle('raw', v),
        ),
        if (facts.teamsEnabled)
          ReportCheckOption(
            label: l10n.standingsTeam,
            value: options.team,
            onChanged: (v) => toggle('team', v),
          ),
        if (facts.numbersEnabled)
          ReportCheckOption(
            label: l10n.standingsPilotNumber,
            value: options.number,
            onChanged: (v) => toggle('num', v),
          ),
        if (facts.classesEnabled)
          ReportCheckOption(
            label: l10n.standingsPilotClass,
            value: options.pilotClass,
            onChanged: (v) => toggle('cls', v),
          ),
      ],
    ),
    ReportControlGroup(
      title: l10n.standingsDetail,
      children: [
        ReportCheckOption(
          label: l10n.standingsFlightDetails,
          help: facts.disciplineLabel == 'F3J'
              ? l10n.standingsFlightDetailsF3J
              : l10n.standingsFlightDetailsF5J,
          value: options.details,
          onChanged: (v) => toggle('det', v),
        ),
        if (StandingsOptions.provisionalApplies(facts))
          ReportCheckOption(
            label: l10n.standingsProvisional,
            help: _provisionalHelp(l10n, facts, options),
            value: options.provisional,
            onChanged: (v) => toggle('prov', v),
          ),
      ],
    ),
  ];
}

String _roundLabel(AppLocalizations l10n, ReportsFacts facts, int round) {
  final fact = facts.roundFact(round);
  final partly = fact != null && fact.scored > 0 && fact.scored < fact.total;
  return partly
      ? l10n.standingsRoundLabelPartial(round)
      : l10n.standingsRoundLabel(round);
}

String _provisionalHelp(
  AppLocalizations l10n,
  ReportsFacts facts,
  StandingsOptions options,
) {
  final partial = facts.rounds
      .where((r) => r.scored > 0 && r.scored < r.total)
      .map((r) => r.ordinal)
      .firstOrNull;
  if (options.provisional && partial == null) {
    return l10n.standingsProvHelpNone;
  } else if (options.provisional && partial != null) {
    return l10n.standingsProvHelpPartial(partial);
  }
  final full = facts.lastFullyScoredRound;
  return full == 0
      ? l10n.standingsProvHelpNoFull
      : l10n.standingsProvHelpFull(full);
}
