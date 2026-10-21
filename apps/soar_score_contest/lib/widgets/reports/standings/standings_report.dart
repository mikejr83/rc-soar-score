import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../services/new_contest/date_range_text.dart';
import '../../../services/reports/report_kind.dart';
import '../../../services/reports/reports_facts.dart';
import '../../../services/reports/standings/standings_layout.dart';
import '../../../services/reports/standings/standings_options.dart';
import '../../../services/reports/standings/standings_report_data.dart';
import '../../../services/reports/standings/standings_status.dart';
import '../../../services/reports/standings/standings_table.dart';
import '../../../services/reports/viewer/page_setup.dart';
import '../../../services/reports/viewer/report_spec.dart';
import '../viewer/report_definition.dart';
import 'standings_controls.dart';
import 'standings_page_body.dart';

/// The Overall Standings report (`plan/ui/contest-administration/reports/
/// overall-standings.md`): every pilot in order of placing with their score
/// for each round, as of the last round shown.
///
/// Rank and total are the stored standing as of that round, read from the
/// results API; the sheet never recalculates them. The viewer asks this report
/// for its filters, options and pages; the report asks the API for the data
/// those filters need, and only again when the rounds shown change.
class StandingsReport extends ReportDefinition {
  const StandingsReport();

  @override
  ReportKind get kind => ReportKind.standings;

  @override
  bool get dependsOnScores => true;

  // The standings are a wide table.
  @override
  PageOrientation get defaultOrientation => PageOrientation.landscape;

  @override
  Map<String, String> defaultFilters(ReportsFacts facts) =>
      StandingsOptions.defaults(facts);

  @override
  ReportCheck check(Map<String, String> filters, ReportsFacts facts) =>
      StandingsOptions.of(filters, facts).check(facts);

  @override
  String filterSummary(Map<String, String> filters, ReportsFacts facts) =>
      StandingsOptions.of(filters, facts).summary;

  /// The data depends on the rounds shown and on Flight details; a column
  /// toggle needs no new read.
  @override
  String? dataKey(Map<String, String> filters, ReportsFacts facts) {
    final options = StandingsOptions.of(filters, facts);
    if (options.check(facts) is ReportEmpty ||
        options.to < 1 ||
        options.to < options.from) {
      return 'none';
    }
    return 'rounds=${options.rounds.join(',')};asOf=${options.to};'
        'det=${options.details ? 1 : 0}';
  }

  @override
  Future<Object?> loadData(ReportDataRequest request) async {
    final options = StandingsOptions.of(request.filters, request.facts);
    if (options.to < 1 || options.to < options.from) {
      return null;
    }
    try {
      return await StandingsReportData.load(
        request.client,
        request.contestId,
        rounds: options.rounds,
        asOf: options.to,
        withDetails: options.details,
      );
    } on NoStoredStandings catch (none) {
      return ReportNoData(
        title: 'No standings stored for round ${none.round} yet',
        body:
            'Standings are stored when scores are saved or recalculated. Save '
            'a score on the Scoring page and the report will show them.',
        actionLabel: 'Open Scoring',
        round: none.round,
      );
    }
  }

  @override
  List<ReportControlGroup> controls(ReportControlsContext context) =>
      standingsControls(
        context,
        StandingsOptions.of(context.filters, context.facts),
      );

  @override
  ReportDocument build(ReportPageContext context) {
    final facts = context.facts;
    final options = StandingsOptions.of(context.filters, facts);
    final data = context.data;
    final contest = facts.contest;
    if (data is! StandingsReportData) {
      return ReportDocument(
        title: 'Overall Results - ${contest.name}',
        subtitle: 'No standings to show',
        pages: [const SizedBox.shrink()],
      );
    }
    final table = StandingsTable.build(
      facts: facts,
      options: options,
      data: data,
    );
    final partial = _partialRounds(facts, options.rounds);
    final layout = StandingsLayout.plan(
      options: options,
      rounds: options.rounds,
      rows: table.rows.length,
      hasPenalty: table.hasPenalty,
      hasPartial: partial.isNotEmpty,
      body: context.bodySize,
      isF3j: table.isF3j,
    );
    final format = StandingsFormat(facts.decimalPlaces);
    final status = StandingsStatus.of(facts, options, data);
    return ReportDocument(
      title: 'Overall Results - ${contest.name}',
      subtitle: _subtitle(facts, options, partial),
      detail: options.isRange
          ? 'Standings as of round ${options.to}; showing rounds '
                '${options.from} to ${options.to}'
          : null,
      status: status.status,
      statusReason: status.reason,
      statusAction: status.action,
      pages: [
        for (final page in layout.pages)
          StandingsPageBody(
            table: table,
            layout: layout,
            page: page,
            format: format,
            partialRounds: partial,
            preview: context.preview,
            size: context.bodySize,
          ),
      ],
    );
  }

  /// The partly scored rounds among [rounds], with their "27 of 30 scored".
  Map<int, String> _partialRounds(ReportsFacts facts, List<int> rounds) => {
    for (final round in rounds)
      if (facts.roundFact(round) case final fact?)
        if (fact.scored > 0 && fact.scored < fact.total)
          round: '${fact.scored} of ${fact.total} scored',
  };

  String _subtitle(
    ReportsFacts facts,
    StandingsOptions options,
    Map<int, String> partial,
  ) {
    final contest = facts.contest;
    final place = [
      if (contest.city case final city? when city.trim().isNotEmpty) city,
      if (contest.state case final state? when state.trim().isNotEmpty) state,
    ].join(', ');
    final start = ContestTime.inZone(contest.startDateTime, contest.timezone);
    final end = ContestTime.inZone(contest.endDateTime, contest.timezone);
    final total = facts.intendedTotalRounds ?? facts.roundCount;
    return [
      if (place.isNotEmpty) place,
      dateRangeText(start, end),
      ?facts.disciplineLabel,
      'Rounds ${options.from} to ${options.to} of '
          '${total < options.to ? options.to : total}',
      if (partial.isNotEmpty)
        partial.length == 1
            ? 'Round ${partial.keys.first} partly scored'
            : 'Rounds ${partial.keys.join(', ')} partly scored',
    ].join(' · ');
  }
}
