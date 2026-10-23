import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/viewer/page_setup.dart';
import 'package:soar_score_contest/widgets/reports/draw_matrix/draw_matrix_report.dart';
import 'package:soar_score_contest/widgets/reports/viewer/report_definition.dart';

import '../support/draw_matrix_support.dart';

void main() {
  final facts = factsOfPage(drawnPage(lanes: true));
  final page = DrawMatrixReport();
  final data = syntheticDraw();

  ReportDocument build(Size body, Map<String, String> filters) =>
      page.buildWith(
        ReportPageContext(
          facts: facts,
          filters: {'from': '1', ...filters},
          setup: const PageSetup(PaperSize.letter, PageOrientation.portrait),
          bodySize: body,
          preview: false,
        ),
        data,
      );

  test('a sheet with room carries no notice', () {
    expect(build(const Size(720, 860), {}).notice, isNull);
  });

  test('a crowded sheet names the columns to turn off', () {
    final document = build(const Size(260, 860), {'inf': '1', 'nat': '1'});
    expect(document.notice, contains('Turn off Club, FAI ID or National ID'));
    expect(document.notice, contains('Compact mode'));
  });

  test('compact mode is not suggested when it is already on', () {
    final document = build(const Size(260, 860), {'cmp': '1'});
    expect(document.notice, isNotNull);
    expect(document.notice, isNot(contains('Compact mode')));
  });
}
