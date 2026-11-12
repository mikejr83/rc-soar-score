import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/pages/home_page.dart';
import 'package:soar_score_contest/pages/landing_page.dart';

import '../support/interact.dart';
import '../support/launch_app.dart';
import '../support/open_demo_contest.dart';
import '../support/open_settings.dart';
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

  await journey.step(
    'The status bar sync entry is short and a click stays',
    () async {
      // Where it exists it says a few words, never a time or zone, and does
      // not leave the page. The web build has no sync but refreshes from the
      // service, so its entry reads "Refresh" and a click reloads the page.
      final sync = find.byKey(const ValueKey('shell-sync-status'));
      if (kIsWeb) {
        // Opening a contest starts a check, which reads "Refreshing" until it
        // answers; the click comes once the entry is ready, and its absence
        // is a failure here.
        await pumpUntilFound(
          tester,
          find.descendant(of: sync, matching: find.text('Refresh')),
        );
      } else if (sync.evaluate().isEmpty) {
        return;
      }
      expect(
        find.descendant(
          of: sync,
          matching: find.textContaining(RegExp(r'\d{1,2}[/.]\d{1,2}')),
        ),
        findsNothing,
      );
      await tapVisible(tester, sync);
      expect(find.text('Workspace'), findsWidgets);
      if (kIsWeb) {
        // The refresh finishes, successfully, and the entry offers it again.
        await tester.pump();
        await pumpUntilFound(
          tester,
          find.descendant(of: sync, matching: find.text('Refresh')),
        );
        expect(find.text('Refresh failed'), findsNothing);
        await pumpUntilFound(tester, find.text('Workspace'));
      }
    },
  );

  await journey.step('Settings lists the open source licences', () async {
    await openSettings(tester);
    await pumpUntilFound(tester, find.text('About'));
    await pumpUntilFound(tester, find.text('Open source licences'));
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    await goToMainPage(tester);
    await pumpUntilFound(tester, find.byType(HomePage));
  });
}
