import 'package:material_ui/material_ui.dart';
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
        // The page follows the button: no scrolling needed to reach it.
        await tester.pumpAndSettle();
        final button = find.text('See group results');
        expect(button, findsOneWidget);
        final rect = tester.getRect(button);
        final viewHeight =
            tester.view.physicalSize.height / tester.view.devicePixelRatio;
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(viewHeight));
      },
    );
    await journey.step('The overview shows the round as submitted', () async {
      final pilot = contest.pilotNames.first;
      // Leave and come back, so the page asks the API again.
      await openPath(tester, pilotPath(contest.id, pilotId));
      await pumpUntilFound(tester, find.text('2 rounds'));
      expect(find.text('Submitted'), findsWidgets);
      expect(find.text('Next to score'), findsOneWidget);
      // The chip is outlined: only the Enter button is filled.
      final chip = find.ancestor(
        of: find.text('Next to score'),
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.decoration is ShapeDecoration,
        ),
      );
      expect(
        (tester.widget<Container>(chip.first).decoration! as ShapeDecoration)
            .color,
        isNull,
      );
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
        await tester.tap(find.byTooltip('Back'));
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
    await journey.step('Next and Previous load each round', () async {
      // Leave sideways first: reopening the same address would keep the
      // page as step 3.7 left it, scrolled down.
      await openPath(tester, resultsPath(contest.id));
      await tester.pump(const Duration(milliseconds: 300));
      await openPath(tester, scoreEntryPath(contest.id, pilotId, '1'));
      await pumpUntilFound(tester, find.text('Time flown'));
      expect(find.textContaining('Round 1'), findsOneWidget);
      final stored = tester
          .widget<TextField>(await fieldFor(tester, 'Time flown'))
          .controller!
          .text;
      expect(stored, isNotEmpty);

      // Round 2 has no score: the form is empty and can be filled in.
      await tester.tap(find.byTooltip('Next round'));
      await pumpUntilFound(tester, find.textContaining('Round 2'));
      await pumpUntilFound(tester, find.text('Time flown'));
      final empty = tester.widget<TextField>(
        await fieldFor(tester, 'Time flown'),
      );
      expect(empty.controller!.text, isEmpty);
      expect(empty.enabled, isTrue);
      await scrollTo(tester, find.text('Submit score'));
      expect(find.text('Submit score'), findsOneWidget);

      // Round 2 is the next to score, so Next stops here.
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.chevron_right),
            )
            .onPressed,
        isNull,
      );

      // Back to round 1: its own stored score, read-only.
      await tester.tap(find.byTooltip('Previous round'));
      await pumpUntilFound(tester, find.textContaining('Round 1'));
      await pumpUntilFound(tester, find.text('Time flown'));
      final back = tester.widget<TextField>(
        await fieldFor(tester, 'Time flown'),
      );
      expect(back.controller!.text, stored);
      expect(back.enabled, isFalse);
    });
    await journey.step(
      'A guest who signs in keeps their entries with the account',
      () async {
        final pilot = contest.pilotNames.first;
        // The same link, now with the option to sign in from it.
        await openPath(tester, invitationPath(contest.credentialOf(pilot)));
        await pumpUntilFound(tester, find.text('Hello, $pilot'));
        await tapVisible(
          tester,
          find.widgetWithText(OutlinedButton, 'Sign in'),
        );
        // Signed in, the link asks to continue as the account.
        await pumpUntilFound(tester, find.text('Continue as Penny Pilot'));
        expect(find.text('Continue as guest'), findsOneWidget);
        await tapVisible(tester, find.text('Continue as Penny Pilot'));
        // The pilot overview acts as the account and still shows round 1.
        await pumpUntilFound(tester, find.text('2 rounds'));
        expect(find.text('Submitted'), findsOneWidget);
        expect(find.text('Next to score'), findsOneWidget);
        final uri = router.routeInformationProvider.value.uri;
        expect(uri.toString(), isNot(contains('invitations')));
        expect(uri.pathSegments, contains(pilotId));
      },
    );
    await journey.step('Signing out ends the session of the account', () async {
      await openPath(tester, '/');
      await pumpUntilFound(tester, find.text('Signed in as Penny Pilot'));
      await tapVisible(tester, find.widgetWithText(OutlinedButton, 'Sign out'));
      await pumpUntilFound(
        tester,
        find.widgetWithText(FilledButton, 'Sign in'),
      );
      // The account's session is gone from this device, so the pilot's page
      // no longer opens from it.
      await openPath(tester, pilotPath(contest.id, pilotId));
      await tester.pumpAndSettle();
      expect(find.text('2 rounds'), findsNothing);
    });
    await journey.step('The link opens again as a guest', () async {
      final pilot = contest.pilotNames.first;
      await openPath(tester, invitationPath(contest.credentialOf(pilot)));
      await pumpUntilFound(tester, find.text('Hello, $pilot'));
      await tapVisible(tester, find.text('Continue as guest'));
      await pumpUntilFound(tester, find.text('2 rounds'));
      expect(find.text('Submitted'), findsOneWidget);
    });
  });
}
