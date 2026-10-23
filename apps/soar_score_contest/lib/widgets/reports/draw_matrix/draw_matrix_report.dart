import 'package:flutter/widgets.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../services/matrix/matrix_page_data.dart';
import '../../../services/new_contest/date_range_text.dart';
import '../../../services/reports/draw_matrix/draw_matrix_data.dart';
import '../../../services/reports/draw_matrix/draw_matrix_layout.dart';
import '../../../services/reports/draw_matrix/draw_matrix_options.dart';
import '../../../services/reports/report_kind.dart';
import '../../../services/reports/reports_facts.dart';
import '../../../services/reports/viewer/page_setup.dart';
import '../../../services/reports/viewer/report_spec.dart';
import '../viewer/report_definition.dart';
import 'draw_matrix_controls.dart';
import 'draw_matrix_page_body.dart';

/// The Draw Matrix document (`plan/ui/contest-administration/reports/
/// draw-matrix.md`, printed title "Flight Matrix"): each round and group with
/// the pilots flying in it, for the boards and the flight line.
///
/// The matrix is read once; the round range, compact mode and the extra
/// columns are applied to it, so changing them redraws at once.
class DrawMatrixReport extends DataReportDefinition<DrawMatrixData> {
  const DrawMatrixReport();

  @override
  ReportKind get kind => ReportKind.matrix;

  // A list of names down a page: portrait.
  @override
  PageOrientation get defaultOrientation => PageOrientation.portrait;

  @override
  Map<String, String> defaultFilters(ReportsFacts facts) =>
      DrawMatrixOptions.defaults(facts);

  @override
  ReportCheck check(Map<String, String> filters, ReportsFacts facts) =>
      DrawMatrixOptions.of(filters, facts).check();

  @override
  String filterSummary(Map<String, String> filters, ReportsFacts facts) =>
      DrawMatrixOptions.of(filters, facts).summary;

  /// One read serves every range and option; a redraw changes the revision,
  /// and so the key.
  @override
  String? dataKey(Map<String, String> filters, ReportsFacts facts) =>
      'matrix=${facts.matrixRevision}';

  @override
  Future<ReportLoad<DrawMatrixData>> loadData(ReportDataRequest request) async {
    final page = await MatrixPageData.forContest(
      request.client,
      request.facts.contest,
    );
    return ReportLoaded(DrawMatrixData.of(page));
  }

  @override
  List<ReportControlGroup> controls(ReportControlsContext context) =>
      drawMatrixControls(
        context,
        DrawMatrixOptions.of(context.filters, context.facts),
      );

  @override
  ReportDocument buildWithout(ReportPageContext context) => ReportDocument(
    title: 'Flight Matrix - ${context.facts.contest.name}',
    subtitle: 'No matrix to show',
    pages: const [SizedBox.shrink()],
  );

  @override
  ReportDocument buildWith(ReportPageContext context, DrawMatrixData data) {
    final facts = context.facts;
    final options = DrawMatrixOptions.of(context.filters, facts);
    final layout = DrawMatrixLayout.plan(
      data: data,
      options: options,
      body: context.bodySize,
      teams: facts.teamsEnabled && options.teamChosen,
      numbers: facts.numbersEnabled && options.numberChosen,
      classes: facts.classesEnabled && options.classChosen,
    );
    return ReportDocument(
      title: 'Flight Matrix - ${facts.contest.name}',
      subtitle: _subtitle(facts, options),
      notice: layout.crowded ? _crowdedNotice(facts, options) : null,
      detail: options.hasUndrawn ? 'Rounds 1 to ${options.drawn} drawn' : null,
      pages: [
        for (var i = 0; i < layout.pages.length; i++)
          DrawMatrixPageBody(
            layout: layout,
            page: layout.pages[i],
            number: i + 1,
            size: context.bodySize,
          ),
      ],
    );
  }

  /// The venue and dates, then the range when it is a slice.
  String _subtitle(ReportsFacts facts, DrawMatrixOptions options) {
    final contest = facts.contest;
    final place = [
      if (contest.city case final city? when city.trim().isNotEmpty) city,
      if (contest.state case final state? when state.trim().isNotEmpty) state,
    ].join(', ');
    final start = ContestTime.inZone(contest.startDateTime, contest.timezone);
    final end = ContestTime.inZone(contest.endDateTime, contest.timezone);
    return [
      if (place.isNotEmpty) place,
      dateRangeText(start, end),
      if (!options.isAll)
        'Rounds ${options.from} to ${options.to} of ${options.drawn}',
    ].join(' · ');
  }

  /// Advice for a sheet whose columns need more room than the page has, naming
  /// the columns that are on and can be turned off.
  String _crowdedNotice(ReportsFacts facts, DrawMatrixOptions options) {
    final off = [
      if (options.showClub) 'Club',
      if (options.showFai) 'FAI ID',
      if (options.showNational) 'National ID',
      if (facts.classesEnabled && options.classChosen) 'Pilot class',
      if (facts.teamsEnabled && options.teamChosen) 'Team',
      if (facts.numbersEnabled && options.numberChosen) 'Pilot number',
    ];
    final tail = options.compact
        ? ''
        : ' Compact mode also gives the columns more room.';
    return off.isEmpty
        ? 'Some rows wrap onto a second line. Pilot names are long for this '
              'page.$tail'
        : 'The columns need more room than this page has, so some rows wrap '
              'onto a second line. Turn off ${_list(off)} in Options to give '
              'the pilot column more room.$tail';
  }

  String _list(List<String> items) => items.length == 1
      ? items.single
      : '${items.sublist(0, items.length - 1).join(', ')} or ${items.last}';
}
