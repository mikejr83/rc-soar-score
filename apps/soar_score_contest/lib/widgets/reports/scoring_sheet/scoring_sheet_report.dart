import 'package:flutter/widgets.dart';

import '../../../services/reports/report_contest_line.dart';
import '../../../services/reports/report_kind.dart';
import '../../../services/reports/reports_facts.dart';
import '../../../services/reports/scoring_sheet/scoring_sheet_columns.dart';
import '../../../services/reports/scoring_sheet/scoring_sheet_data.dart';
import '../../../services/reports/scoring_sheet/scoring_sheet_layout.dart';
import '../../../services/reports/scoring_sheet/scoring_sheet_options.dart';
import '../../../services/reports/viewer/page_setup.dart';
import '../../../services/reports/viewer/report_spec.dart';
import '../../../services/scoring/scoring_page_data.dart';
import '../viewer/report_definition.dart';
import '../viewer/report_sheet_page.dart';
import 'scoring_sheet_controls.dart';
import 'scoring_sheet_page_body.dart';

/// The Scoring Sheet document (`plan/ui/contest-administration/reports/
/// scoring-sheet.md`): the draw by round and group with blank cells for
/// officials to write every score component in by hand.
///
/// The matrix and scores are read once; the round range, retired pilots,
/// Pre-fill and the columns are applied to them, so changing them redraws at
/// once. The report picks Portrait when every column fits across it and
/// Landscape otherwise, until the director chooses; columns that fit neither
/// way continue on further pages, side by side.
class ScoringSheetReport extends DataReportDefinition<ScoringSheetData> {
  const ScoringSheetReport();

  @override
  ReportKind get kind => ReportKind.sheet;

  @override
  PageOrientation get defaultOrientation => PageOrientation.landscape;

  /// The whole page, header and footer included, keeps further from the edge
  /// than the frame's margin so a printer does not cut the sheet off.
  @override
  double get extraSideMargin => ScoringSheetStyle.sideMargin;

  /// Portrait when the columns fit across it at their narrowest, else
  /// Landscape. Before the data is read the lanes are not known, so it waits
  /// in Landscape.
  @override
  PageOrientation suggestedOrientation(
    Map<String, String> filters,
    ReportsFacts facts,
    Object? data,
    PaperSize paper,
  ) {
    if (data is! ScoringSheetData) {
      return defaultOrientation;
    }
    final columns = _columns(
      ScoringSheetOptions.of(filters, facts),
      data,
      facts,
    );
    final portraitWidth = SheetLayout.bodySize(
      PageSetup(paper, PageOrientation.portrait),
      extraSide: extraSideMargin,
    ).width;
    return ScoringSheetColumns.fits(columns, portraitWidth)
        ? PageOrientation.portrait
        : PageOrientation.landscape;
  }

  List<ScoringSheetColumn> _columns(
    ScoringSheetOptions options,
    ScoringSheetData data,
    ReportsFacts facts,
  ) => ScoringSheetColumns.forContest(
    discipline: data.discipline ?? facts.disciplineLabel,
    lanes: data.hasLanes,
    restart: data.motorRestart,
    options: options,
  );

  @override
  Map<String, String> defaultFilters(ReportsFacts facts) =>
      ScoringSheetOptions.defaults(facts);

  @override
  ReportCheck check(Map<String, String> filters, ReportsFacts facts) =>
      ScoringSheetOptions.of(filters, facts).check();

  @override
  String filterSummary(Map<String, String> filters, ReportsFacts facts) =>
      ScoringSheetOptions.of(filters, facts).summary;

  /// One read serves every range and option; a redraw or a score changes the
  /// key.
  @override
  String? dataKey(Map<String, String> filters, ReportsFacts facts) =>
      'sheet=${facts.matrixRevision}:${facts.scoresSignature}';

  @override
  Future<ReportLoad<ScoringSheetData>> loadData(
    ReportDataRequest request,
  ) async {
    final page = await ScoringPageData.load(request.client, request.contestId);
    return ReportLoaded(ScoringSheetData.of(facts: request.facts, page: page));
  }

  @override
  List<ReportControlGroup> controls(ReportControlsContext context) {
    final options = ScoringSheetOptions.of(context.filters, context.facts);
    final data = context.data;
    return scoringSheetControls(
      context,
      options,
      data is ScoringSheetData ? _columns(options, data, context.facts) : null,
      SheetLayout.bodySize(context.setup, extraSide: extraSideMargin).width,
    );
  }

  @override
  ReportDocument buildWithout(ReportPageContext context) => ReportDocument(
    title: _title(context.facts),
    subtitle: 'No matrix to show',
    pages: const [SizedBox.shrink()],
  );

  @override
  ReportDocument buildWith(ReportPageContext context, ScoringSheetData data) {
    final facts = context.facts;
    final options = ScoringSheetOptions.of(context.filters, facts);
    final layout = ScoringSheetLayout.plan(
      data: data,
      options: options,
      body: context.bodySize,
    );
    final range = options.range;
    return ReportDocument(
      title: _title(facts),
      subtitle: [
        contestPlaceAndDates(facts.contest),
        if (!range.isAll)
          'Rounds ${range.from} to ${range.to} of ${range.drawn}',
      ].join(' · '),
      detail: range.hasUndrawn ? 'Rounds 1 to ${range.drawn} drawn' : null,
      notice: layout.fitsAcross
          ? null
          : 'The columns don’t fit across this page, so they continue on '
                'further pages. Pages for the same rows are side by side: '
                'tape them together left to right. A wider page or fewer '
                'columns fits on one.',
      pages: [
        for (var i = 0; i < layout.pages.length; i++)
          ScoringSheetPageBody(
            layout: layout,
            page: layout.pages[i],
            number: i + 1,
            size: context.bodySize,
          ),
      ],
    );
  }

  String _title(ReportsFacts facts) =>
      'Official Scoring - ${facts.contest.name}';
}
