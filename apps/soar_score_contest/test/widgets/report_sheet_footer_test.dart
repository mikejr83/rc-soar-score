import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/result_status.dart';
import 'package:soar_score_contest/services/reports/viewer/page_setup.dart';
import 'package:soar_score_contest/widgets/reports/viewer/report_sheet_page.dart';

Future<void> _pump(WidgetTester tester, {ResultStatus? status}) async {
  const setup = PageSetup(PaperSize.letter, PageOrientation.portrait);
  tester.view.physicalSize = const Size(900, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: ReportSheetPage(
            setup: setup,
            title: 'Flight Matrix - Gator Cup',
            subtitle: 'Lake Wales, Florida',
            detail: null,
            reportName: 'Draw Matrix',
            pageNumber: 1,
            pageCount: 12,
            generated: 'Generated 23 Oct 2026, 17:40',
            status: status,
            body: const SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final status in [
    null,
    ResultStatus.preliminary,
    ResultStatus.official,
  ]) {
    testWidgets('the generated time is centred on the page ($status)', (
      tester,
    ) async {
      await _pump(tester, status: status);
      final page = tester.getRect(find.byType(ReportSheetPage));
      final generated = tester.getRect(
        find.text('Generated 23 Oct 2026, 17:40'),
      );
      expect(generated.center.dx, closeTo(page.center.dx, 0.5));
    });
  }
}
