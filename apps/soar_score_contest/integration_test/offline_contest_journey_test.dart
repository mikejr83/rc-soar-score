import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:soar_score_contest/pages/home_page.dart';
import 'package:soar_score_contest/pages/landing_page.dart';

import 'support/launch_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // One test per file run: `launchApp` starts the real app, which holds the
  // demo database and the embedded server's port for the life of the process.
  // A second `main()` in the same process finds them still in use.
  testWidgets('offline journey: landing, contest list, open a contest', (
    tester,
  ) async {
    await launchApp(tester);

    // A restored sign-in (the developer's own Auth0 session) sends the router
    // straight to the main page, so the landing page only shows when signed
    // out.
    await pumpUntilFound(
      tester,
      find.byWidgetPredicate(
        (w) => w is LandingPage || w is HomePage,
        description: 'LandingPage or HomePage',
      ),
    );
    if (find.byType(LandingPage).evaluate().isNotEmpty) {
      await tester.tap(find.text('Continue offline'));
    }

    await pumpUntilFound(tester, find.byType(HomePage));
    // The name shows in the list row and, on wide windows, in the detail
    // pane, so target the row.
    final contestRow = find.descendant(
      of: find.byType(ListTile),
      matching: find.text('Autumn F5J Classic'),
    );
    await pumpUntilFound(tester, contestRow);

    await tester.tap(contestRow);

    // Contest scope shows the contest's own destinations.
    await pumpUntilFound(tester, find.text('Workspace'));
    expect(find.text('Matrix'), findsWidgets);
  });
}
