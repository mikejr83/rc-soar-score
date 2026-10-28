import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/pages/home_page.dart';
import 'package:soar_score_contest/pages/landing_page.dart';

import '../support/interact.dart';
import '../support/launch_app.dart';
import '../support/open_demo_contest.dart';
import 'journey.dart';

/// Phase 1: start the app on the landing page and reach the main page.
Future<void> runStartPhase(Journey journey, JourneyContext data) async {
  final tester = journey.tester;

  await journey.step('Landing page has no app shell, then continue', () async {
    await launchApp(tester);
    await pumpUntilFound(
      tester,
      find.byWidgetPredicate(
        (w) => w is LandingPage || w is HomePage,
        description: 'LandingPage or HomePage',
      ),
    );
    // A restored Auth0 session (Windows) goes straight to the main page.
    if (find.byType(LandingPage).evaluate().isNotEmpty) {
      expect(find.byType(NavigationRail), findsNothing);
      await continueFromLanding(tester);
    }
    await pumpUntilFound(tester, find.byType(HomePage));
  });

  await journey.step('Main page lists the demo contests', () async {
    await pumpUntilFound(tester, find.text('Contests'));
    for (final name in const ['Autumn F5J Classic', 'Club Thermal Fun Fly']) {
      await pumpUntilFound(
        tester,
        find.descendant(of: find.byType(ListTile), matching: find.text(name)),
      );
    }
  });

  await journey.step('A demo contest opens with its own rail', () async {
    await goToMainPage(tester);
    await openContest(tester, 'Autumn F5J Classic');
    expect(find.text('Matrix'), findsWidgets);
    await pumpUntilFound(tester, find.text('Workspace'));
  });
}
