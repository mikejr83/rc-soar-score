import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The web opens a report in a new tab, which a journey cannot drive, so
  // this journey is native-only.
  testWidgets(
    'a completed contest has no Provisional option in Overall Standings (native)',
    (tester) async {
      await openMainPage(tester);
      await openContest(tester, 'Autumn F5J Classic');
      await tapRail(tester, 'Reports');
      await pumpUntilFound(tester, find.text('Reports are built from'));

      await tapVisible(
        tester,
        find.byKey(const ValueKey('report-open-standings')),
      );
      await pumpUntilFound(tester, find.text('Rank'));

      // Every score is final: the Detail group has no Provisional switch, but
      // still offers Flight details.
      expect(
        find.widgetWithText(CheckboxListTile, 'Flight details'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(CheckboxListTile, 'Provisional'),
        findsNothing,
      );
    },
    skip: kIsWeb,
  );
}
