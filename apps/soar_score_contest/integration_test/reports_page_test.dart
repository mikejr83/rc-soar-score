import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The Overall Standings report reads the stored results of a contest that is
  // being scored. The readiness list and the Draw Matrix viewer are steps of
  // the lifecycle journey (phase 4); this one moves there with phase 6.
  testWidgets('Overall Standings shows the standings and follows its options', (
    tester,
  ) async {
    await openMainPage(tester);
    await openContest(tester, 'Mountain States Team F5J');
    await tapRail(tester, 'Reports');
    await pumpUntilFound(tester, find.text('Reports are built from'));

    await tapVisible(
      tester,
      find.byKey(const ValueKey('report-open-standings')),
    );
    await pumpUntilFound(tester, find.text('Rank'));

    // The heading, the columns and the pilots in their stored order.
    expect(find.textContaining('Overall Results - '), findsWidgets);
    expect(find.text('Total'), findsWidgets);
    expect(find.text('R1'), findsWidgets);
    expect(find.text('Raw'), findsNothing);

    // An option adds its column at once.
    await tapVisible(
      tester,
      find.widgetWithText(CheckboxListTile, 'Raw score'),
    );
    await pumpUntilFound(tester, find.text('Raw'));

    await tapVisible(tester, find.byKey(const ValueKey('viewer-back')));
    await pumpUntilFound(tester, find.text('Reports are built from'));
  });
}
