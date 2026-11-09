import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/pilot_invitations.dart';
import 'package:soar_score_contest/services/reports/viewer/platform_report_printer.dart';
import 'package:soar_score_contest/services/reports/viewer/report_printers.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';

/// A ready demo contest: a drawn matrix, nothing scored yet.
const _contest = 'Front Range F5J Open';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The viewer opens in place on native and in a new tab on the web, which a
  // journey cannot drive, so this journey is native-only (like
  // `report_printing_test.dart`).
  testWidgets('Pilot Scoring Cards: QR reminder and print (native)', (
    tester,
  ) async {
    final printed = <Uint8List>[];
    final original = ReportPrinters.current;
    addTearDown(() => ReportPrinters.current = original);
    ReportPrinters.current = PlatformReportPrinter(
      printDialog: (job, pdf) async {
        printed.add(pdf);
        return true;
      },
      saveFile: (fileName, pdf) async => fileName,
    );

    // Without invitations no card has a QR code, which is what the print
    // reminder below is about. (The app's own source asks the hosted server,
    // which this journey does not have.)
    final source = PilotInvitationSources.current;
    addTearDown(() => PilotInvitationSources.current = source);
    PilotInvitationSources.current = const UnavailablePilotInvitationSource();

    await openMainPage(tester);
    await openContest(tester, _contest);
    await tapRail(tester, 'Reports');
    await pumpUntilFound(tester, find.text('Reports are built from'));
    await tapVisible(tester, find.byKey(const ValueKey('report-open-cards')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('viewer-title')));

    // The cards themselves are checked in the lifecycle journey (phase 4).
    await pumpUntilFound(tester, find.byKey(const ValueKey('cards-summary')));

    // No invitation exists yet, so Print reminds about the missing QR codes.
    // Printing without them stays possible.
    await tapVisible(tester, find.byKey(const ValueKey('viewer-print')));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('cards-reminder-dialog')),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('cards-reminder-without')),
    );
    await pumpUntilFound(tester, find.textContaining('Sent to the printer'));
    expect(printed, hasLength(1));
    expect(String.fromCharCodes(printed.single.take(5)), '%PDF-');
  }, skip: kIsWeb);
}
