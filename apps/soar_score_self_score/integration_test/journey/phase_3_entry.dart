import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/router.dart';

import '../support/director_api.dart';
import '../support/launch_app.dart';
import 'journey.dart';
import '../support/entry_form.dart';
import 'phase_2_invitation.dart';

/// Phase 3: the pilot enters round 1 and the score survives leaving the page.
Future<void> phase3Entry(
  WidgetTester tester,
  Journey journey,
  SeededContest contest,
  String pilotId,
) async {
  await journey.phase(3, 'Enter the first round', () async {
    await journey.step('Enter opens the F5J entry form', () async {
      await tapVisible(tester, find.text('Enter'));
      await pumpUntilFound(tester, find.text('Time flown'));
      expect(find.text('Launch height (m)'), findsOneWidget);
      expect(find.text('Landing'), findsWidgets);
      await scrollTo(tester, find.text('Submit score'));
      expect(find.text('Submit score'), findsOneWidget);
    });
    await journey.step('Bad entries are explained and not sent', () async {
      // 6:75 is not a time: the seconds are 00 to 59.
      await tester.enterText(await fieldFor(tester, 'Time flown'), '675');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('must be 00 to 59'), findsOneWidget);
    });
    await journey.step('Fill in time, height and landing', () async {
      // 900 is 9:00, 540 s of a 600 s window.
      await tester.enterText(await fieldFor(tester, 'Time flown'), '900');
      await tester.enterText(await fieldFor(tester, 'Launch height (m)'), '45');
      await tester.pump(const Duration(milliseconds: 300));
      await chooseLanding(tester);
    });
    await journey.step(
      'Submit shows the score the server calculated',
      () async {
        await tapVisible(tester, find.text('Submit score'));
        await pumpUntilFound(tester, find.textContaining('Score: '));
        expect(find.text('Score: 567.5'), findsOneWidget);
        expect(find.textContaining('Entered by '), findsOneWidget);
        expect(find.text('Submit score'), findsNothing);
        await scrollTo(tester, find.text('See group results'));
        expect(find.text('See group results'), findsOneWidget);
      },
    );
    await journey.step('The overview shows the round as submitted', () async {
      final pilot = contest.pilotNames.first;
      // Leave and come back, so the page asks the API again.
      await openPath(tester, pilotPath(contest.id, pilotId));
      await pumpUntilFound(tester, find.text('2 rounds'));
      expect(find.text('Submitted'), findsWidgets);
      expect(find.text('Next to score'), findsOneWidget);
      expect(find.textContaining(pilot), findsWidgets);
    });
    await journey.step('View opens the submitted round read-only', () async {
      // The submitted round offers View; the next round offers Enter.
      expect(find.text('View'), findsOneWidget);
      await tapVisible(tester, find.text('View'));
      await pumpUntilFound(tester, find.text('Time flown'));
      // It is the read-only score entry page, not the group results: nothing
      // can be submitted, and the button links on to the group results.
      expect(find.text('Submit score'), findsNothing);
      await scrollTo(tester, find.text('See group results'));
      expect(find.text('See group results'), findsOneWidget);
    });
    await journey.step(
      'Flight Results opens the group and back returns',
      () async {
        await openPath(tester, pilotPath(contest.id, pilotId));
        await pumpUntilFound(tester, find.text('2 rounds'));
        // Only the submitted round has a score, so only it offers the button.
        expect(find.text('Flight Results'), findsOneWidget);
        await tapVisible(tester, find.text('Flight Results'));
        await pumpUntilFound(tester, find.text('Preliminary'));
        expect(find.text('Group results'), findsNothing);
        await tester.tap(find.byTooltip('Back to pilot overview'));
        await pumpUntilFound(tester, find.text('2 rounds'));
        expect(find.text('Flight Results'), findsOneWidget);
      },
    );
    await journey.step('The stored entry is read-only when reopened', () async {
      await openPath(tester, scoreEntryPath(contest.id, pilotId, '1'));
      await pumpUntilFound(tester, find.text('Time flown'));
      // The stored values come back from the server, and nothing can be sent.
      final time = tester.widget<TextField>(
        await fieldFor(tester, 'Time flown'),
      );
      expect(time.controller!.text, isNotEmpty);
      expect(time.enabled, isFalse);
      await scrollTo(tester, find.text('Flight penalty (points)'));
      expect(find.text('Submit score'), findsNothing);
    });
  });
}
