import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/viewer/platform_report_printer.dart';
import 'package:soar_score_contest/services/reports/viewer/report_pdf_builder.dart';
import 'package:soar_score_contest/services/reports/viewer/report_print_result.dart';

class _Builder implements ReportPdfBuilder {
  _Builder({this.fail = false});

  final bool fail;

  @override
  Future<Uint8List> build(ReportPrintJob job) async {
    if (fail) {
      throw StateError('no pdf');
    }
    return Uint8List.fromList([1, 2, 3]);
  }
}

const _job = ReportPrintJob(
  title: 'Overall Standings – Gator Cup',
  pageCount: 1,
  paperLabel: 'Letter',
  orientationLabel: 'Portrait',
);

void main() {
  test('print answers sent or cancelled from the dialog', () async {
    Uint8List? received;
    var answer = true;
    final printer = PlatformReportPrinter(
      builder: _Builder(),
      printDialog: (job, pdf) async {
        received = pdf;
        return answer;
      },
    );
    expect(await printer.print(_job), ReportPrintResult.sent);
    expect(received, [1, 2, 3]);
    answer = false;
    expect(await printer.print(_job), ReportPrintResult.cancelled);
  });

  test('a build or dialog error is reported as failed', () async {
    final printer = PlatformReportPrinter(
      builder: _Builder(fail: true),
      printDialog: (job, pdf) async => true,
    );
    expect(await printer.print(_job), ReportPrintResult.failed);
    expect(await printer.savePdf(_job), ReportPrintResult.failed);
  });

  test('savePdf names the file and reports a cancelled save', () async {
    String? name;
    var saved = true;
    final printer = PlatformReportPrinter(
      builder: _Builder(),
      saveFile: (fileName, pdf) async {
        name = fileName;
        return saved;
      },
    );
    expect(await printer.savePdf(_job), ReportPrintResult.sent);
    expect(name, 'Overall Standings – Gator Cup.pdf');
    saved = false;
    expect(await printer.savePdf(_job), ReportPrintResult.cancelled);
  });

  test('file names drop characters a file system refuses', () {
    expect(
      PlatformReportPrinter.fileNameFor('Draw Matrix – A/B: "Cup"'),
      'Draw Matrix – A-B- -Cup-.pdf',
    );
  });
}
