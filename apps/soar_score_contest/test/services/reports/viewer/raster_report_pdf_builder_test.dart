import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/viewer/page_setup.dart';
import 'package:soar_score_contest/services/reports/viewer/raster_report_pdf_builder.dart';
import 'package:soar_score_contest/services/reports/viewer/report_print_result.dart';

ReportPrintJob _job(PageSetup setup, int pages) => ReportPrintJob(
  title: 'Overall Standings – Cup',
  pageCount: pages,
  paperLabel: setup.paper.label,
  orientationLabel: setup.orientation.label,
  setup: setup,
  pages: [
    for (var i = 0; i < pages; i++)
      SizedBox(
        width: setup.width,
        height: setup.height,
        child: ColoredBox(
          color: Colors.white,
          child: Center(child: Text('Page ${i + 1}')),
        ),
      ),
  ],
);

void main() {
  const builder = RasterReportPdfBuilder(pixelRatio: 1, compress: false);

  testWidgets('builds one PDF page per sheet page at the paper size', (
    tester,
  ) async {
    const setup = PageSetup(PaperSize.a4, PageOrientation.landscape);
    final bytes = (await tester.runAsync(() => builder.build(_job(setup, 3))))!;

    expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
    final text = latin1.decode(bytes);
    expect(RegExp(r'/Type/Page/').allMatches(text), hasLength(3));
    // A4 landscape: 794 x 1123 px at 96 dpi is 842.25 x 595.5 pt.
    final box = RegExp(r'/MediaBox\[0 0 ([\d.]+) ([\d.]+)\]').firstMatch(text)!;
    expect(double.parse(box.group(1)!), closeTo(842.25, 0.01));
    expect(double.parse(box.group(2)!), closeTo(595.5, 0.01));
  });

  testWidgets('rejects a job with no pages', (tester) async {
    const setup = PageSetup(PaperSize.letter, PageOrientation.portrait);
    final error = await tester.runAsync(() async {
      try {
        await builder.build(_job(setup, 0));
        return null;
      } on ArgumentError catch (error) {
        return error;
      }
    });
    expect(error, isA<ArgumentError>());
  });
}
