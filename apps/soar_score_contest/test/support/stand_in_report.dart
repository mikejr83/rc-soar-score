import 'package:flutter/material.dart';
import 'package:soar_score_contest/services/reports/report_availability.dart';
import 'package:soar_score_contest/services/reports/report_kind.dart';
import 'package:soar_score_contest/services/reports/reports_facts.dart';
import 'package:soar_score_contest/services/reports/result_status.dart';
import 'package:soar_score_contest/services/reports/viewer/page_setup.dart';
import 'package:soar_score_contest/services/reports/viewer/report_print_result.dart';
import 'package:soar_score_contest/services/reports/viewer/report_spec.dart';
import 'package:soar_score_contest/widgets/reports/viewer/report_controls.dart';
import 'package:soar_score_contest/widgets/reports/viewer/report_definition.dart';

/// A report with a round range, one option, a screen-only mark and two pages,
/// to exercise the whole viewer frame without a real report.
class StandInReport extends ReportDefinition {
  const StandInReport({this.rounds = 2, this.pages = 2});

  /// The rounds the range may pick from.
  final int rounds;
  final int pages;

  @override
  ReportKind get kind => ReportKind.standings;

  @override
  bool get dependsOnScores => true;

  @override
  Map<String, String> defaultFilters(ReportsFacts facts) => {
    'from': '1',
    'to': '$rounds',
  };

  @override
  ReportCheck check(Map<String, String> filters, ReportsFacts facts) {
    final from = int.parse(filters['from']!);
    final to = int.parse(filters['to']!);
    if (from > to) {
      return const ReportInvalid('From round must be on or before To round.');
    }
    if (filters['empty'] == '1') {
      return const ReportEmpty(
        title: 'No scores in these rounds',
        body: 'Choose other rounds.',
      );
    }
    return ReportCheck.ok;
  }

  @override
  String filterSummary(Map<String, String> filters, ReportsFacts facts) =>
      'Rounds ${filters['from']}–${filters['to']}';

  @override
  List<ReportControlGroup> controls(ReportControlsContext context) {
    final items = {for (var r = 1; r <= rounds; r++) '$r': 'Round $r'};
    final check = context.check;
    return [
      ReportControlGroup(
        title: 'Filter',
        children: [
          ReportDropdown(
            label: 'From round',
            value: context.filters['from']!,
            items: items,
            onChanged: (value) => context.setFilter('from', value),
          ),
          ReportDropdown(
            label: 'To round',
            value: context.filters['to']!,
            items: items,
            onChanged: (value) => context.setFilter('to', value),
          ),
          ReportFieldMessage(
            text: check is ReportInvalid
                ? check.message
                : 'Only rounds with scores are listed.',
            isError: check is ReportInvalid,
          ),
        ],
      ),
      ReportControlGroup(
        title: 'Options',
        children: [
          ReportCheckOption(
            label: 'Percentage of total',
            value: context.filters['pct'] == '1',
            onChanged: (value) => context.setFilter('pct', value ? '1' : '0'),
          ),
        ],
      ),
    ];
  }

  @override
  ReportDocument build(ReportPageContext context) {
    final filters = context.filters;
    return ReportDocument(
      title: 'Overall Results - ${context.facts.contest.name}',
      subtitle: 'As of round ${filters['to']}',
      status: ResultStatus.preliminary,
      statusReason: 'round 2 has 2 missing scores.',
      statusAction: const ReportAction(
        'Open Scoring',
        ReportDestination.scoring,
      ),
      pages: [
        for (var i = 0; i < pages; i++)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rounds ${filters['from']}-${filters['to']} body ${i + 1}'),
              if (!context.preview) const Text('Screen only mark'),
            ],
          ),
      ],
    );
  }
}

/// A printer that answers with a set result and records the jobs.
class FakeReportPrinter implements ReportPrinter {
  FakeReportPrinter(
    this.result, {
    this.capabilities = const ReportPrintCapabilities(),
  });

  ReportPrintResult result;

  @override
  final ReportPrintCapabilities capabilities;
  final List<ReportPrintJob> printed = [];
  final List<ReportPrintJob> saved = [];

  @override
  Future<ReportPrintResult> print(ReportPrintJob job) async {
    printed.add(job);
    return result;
  }

  @override
  Future<ReportPrintResult> savePdf(ReportPrintJob job) async {
    saved.add(job);
    return result;
  }
}

/// The page setup a test expects after choosing [paper] and [orientation].
PageSetup setupOf(PaperSize paper, PageOrientation orientation) =>
    PageSetup(paper, orientation);
