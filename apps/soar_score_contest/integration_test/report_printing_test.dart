import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:soar_score_contest/services/reports/viewer/platform_report_printer.dart';
import 'package:soar_score_contest/services/reports/viewer/report_printers.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';

/// A ready demo contest: a drawn matrix, nothing scored yet.
const _contest = 'Front Range F5J Open';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // A journey cannot drive the system print dialog or file chooser, so the
  // printer keeps the real PDF engine (it rasterises the real sheet pages)
  // and swaps only the two system dialogs for recorders. Native opens the
  // viewer in place; the web opens a new tab, which a journey cannot drive, so
  // this journey is native-only.
  testWidgets('Print and Save as PDF build a PDF of the sheet (native)', (
    tester,
  ) async {
    final printed = <Uint8List>[];
    final saved = <String, Uint8List>{};
    final original = ReportPrinters.current;
    addTearDown(() => ReportPrinters.current = original);
    ReportPrinters.current = PlatformReportPrinter(
      printDialog: (job, pdf) async {
        printed.add(pdf);
        return true;
      },
      saveFile: (fileName, pdf) async {
        saved[fileName] = pdf;
        return fileName;
      },
    );

    await openMainPage(tester);
    await openContest(tester, _contest);
    await tapRail(tester, 'Reports');
    await pumpUntilFound(tester, find.text('Reports are built from'));
    await tapVisible(tester, find.byKey(const ValueKey('report-open-matrix')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('viewer-title')));

    // The sheet is the Draw Matrix itself: rounds, groups and pilots, and
    // compact mode takes the dependent Additional pilot info option away.
    await pumpUntilFound(
      tester,
      find.textContaining('Group A', findRichText: true),
    );
    expect(find.text('Flight Matrix - $_contest'), findsWidgets);
    await tapVisible(
      tester,
      find.widgetWithText(SwitchListTile, 'Compact mode'),
    );
    expect(find.text('Not available in compact mode'), findsOneWidget);
    await tapVisible(
      tester,
      find.widgetWithText(SwitchListTile, 'Compact mode'),
    );
    expect(find.text('Not available in compact mode'), findsNothing);

    // Print hands a PDF to the print dialog and says so.
    await tapVisible(tester, find.byKey(const ValueKey('viewer-print')));
    await pumpUntilFound(tester, find.textContaining('Sent to the printer'));
    expect(printed, hasLength(1));
    expect(String.fromCharCodes(printed.single.take(5)), '%PDF-');

    // Save as PDF names the file after the report and the contest.
    await tapVisible(tester, find.byKey(const ValueKey('viewer-pdf')));
    await pumpUntilFound(tester, find.textContaining('PDF saved'));
    expect(find.textContaining('$_contest.pdf'), findsOneWidget);
    expect(saved.keys, ['Draw Matrix – $_contest.pdf']);

    // Ctrl+P is the same Print action.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    final end = DateTime.now().add(const Duration(seconds: 30));
    while (printed.length < 2 && DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(printed, hasLength(2));
  }, skip: kIsWeb);
}
