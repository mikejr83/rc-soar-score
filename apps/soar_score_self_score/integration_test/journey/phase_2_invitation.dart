import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/router.dart';

import '../support/director_api.dart';
import '../support/launch_app.dart';
import 'journey.dart';

/// Opens [path] the way a followed link does.
Future<void> openPath(WidgetTester tester, String path) async {
  router.go(path);
  await tester.pump();
  // Wait for the outgoing route to leave the tree before checking the page.
  await tester.pumpAndSettle();
}

/// The [label] button of the Is this you card that names [pilot].
Finder _answer(String pilot, String label) => find.descendant(
  of: find.ancestor(
    of: find.textContaining(pilot),
    matching: find.byType(Card),
  ),
  matching: find.text(label),
);

/// Pumps until [finder] matches nothing.
Future<void> _waitGone(WidgetTester tester, Finder finder) async {
  final end = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isEmpty) return;
  }
  fail('Timed out waiting for $finder to go. On screen: ${screenTexts()}');
}

/// Phase 2: the pilot opens the link from the score card.
///
/// Returns the pilot id of the guest session, read from the overview address.
Future<String> phase2Invitation(
  WidgetTester tester,
  Journey journey,
  SeededContest contest,
) async {
  final pilot = contest.pilotNames.first;
  var pilotId = '';
  await journey.phase(2, 'Open the invitation link', () async {
    await journey.step('The landing page offers sign in and sign up', () async {
      await openPath(tester, '/');
      await pumpUntilFound(
        tester,
        find.text('Score your flights at the field'),
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Sign in'))
            .onPressed,
        isNotNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Sign up'),
            )
            .onPressed,
        isNotNull,
      );
      expect(find.textContaining('coming in a future release'), findsNothing);
    });
    await journey.step('Signing in shows the pilot and the way on', () async {
      // The E2E build signs in as the server's seeded pilot account with no
      // Auth0 round trip (`E2eAuthSession`).
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Sign in'));
      await pumpUntilFound(tester, find.text('Signed in as Penny Pilot'));
      expect(find.widgetWithText(FilledButton, 'My contests'), findsOneWidget);
    });
    await journey.step(
      'My contests asks Is this you for each email match',
      () async {
        // The director typed the pilot's email on two profiles of the contest.
        final yes = contest.pilotNames[2];
        final no = contest.pilotNames[3];
        await contest.linkPilotAccount(yes, state: 'candidate');
        await contest.linkPilotAccount(no, state: 'candidate');
        await tapVisible(
          tester,
          find.widgetWithText(FilledButton, 'My contests'),
        );
        await pumpUntilFound(tester, find.text('Is this you?'));
        expect(find.text('Is this you?'), findsNWidgets(2));
        expect(find.textContaining(yes), findsOneWidget);
        expect(find.textContaining(no), findsOneWidget);
        expect(find.textContaining('E2E Self-Scoring Open'), findsWidgets);
        // No director, email or id on the card.
        expect(find.textContaining('@'), findsNothing);
      },
    );
    await journey.step('Not me drops the match and it stays dropped', () async {
      final no = contest.pilotNames[3];
      await tapVisible(tester, _answer(no, 'Not me'));
      await _waitGone(tester, find.textContaining(no));
      expect(find.text('Is this you?'), findsOneWidget);
      // Leave the page and come back: the answer is on the server.
      await openPath(tester, '/');
      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'My contests'),
      );
      await pumpUntilFound(tester, find.text('Is this you?'));
      expect(find.textContaining(no), findsNothing);
      expect(find.text('Is this you?'), findsOneWidget);
    });
    await journey.step('Yes, that is me links the pilot', () async {
      final yes = contest.pilotNames[2];
      await tapVisible(tester, _answer(yes, "Yes, that's me"));
      await _waitGone(tester, find.text('Is this you?'));
      expect(await contest.linkedPilotNames(), [yes]);
      // Nothing is offered again.
      await openPath(tester, '/');
      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'My contests'),
      );
      await pumpUntilFound(tester, find.text('Your contests'));
      expect(find.text('Is this you?'), findsNothing);
      await openPath(tester, '/');
    });
    await journey.step('Signing out returns to the landing page', () async {
      await tapVisible(tester, find.widgetWithText(OutlinedButton, 'Sign out'));
      await pumpUntilFound(
        tester,
        find.widgetWithText(FilledButton, 'Sign in'),
      );
      expect(find.text('Signed in as Penny Pilot'), findsNothing);
    });
    await journey.step('A link that does not exist is refused', () async {
      await openPath(tester, invitationPath('not-a-real-credential'));
      await pumpUntilFound(tester, find.text('This link does not work'));
      expect(find.text('Continue as guest'), findsNothing);
    });
    await journey.step('A valid link greets the pilot by name', () async {
      await openPath(tester, invitationPath(contest.credentialOf(pilot)));
      await pumpUntilFound(tester, find.text('Hello, $pilot'));
      expect(find.textContaining('E2E Self-Scoring Open'), findsWidgets);
    });
    await journey.step('Continue as guest opens the pilot overview', () async {
      await tapVisible(tester, find.text('Continue as guest'));
      await pumpUntilFound(tester, find.text('2 rounds'));
      // The credential is gone from the address.
      final uri = router.routeInformationProvider.value.uri;
      expect(uri.toString(), isNot(contains('invitations')));
      pilotId = uri.pathSegments[uri.pathSegments.indexOf('pilots') + 1];
      expect(find.text('Next to score'), findsOneWidget);
      expect(find.text('Enter'), findsOneWidget);
      // A guest has no way back in but the card's QR code, so no sign out.
      expect(find.byTooltip('End session'), findsNothing);
    });
    await journey.step(
      'The pilot can copy their own invitation link',
      () async {
        // A browser driven by a test has no focus and refuses the real
        // clipboard, so the copy is caught on the platform channel.
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String?;
            }
            return null;
          },
        );
        try {
          await tapVisible(tester, find.byIcon(Icons.more_vert));
          await pumpUntilFound(tester, find.text('Copy invitation link'));
          await tapVisible(tester, find.text('Copy invitation link'));
          await pumpUntilFound(tester, find.text('Invitation link copied'));
        } finally {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          );
        }
        expect(copied, endsWith(contest.credentialOf(pilot)));
        await tester.pump(const Duration(seconds: 5));
      },
    );
    await journey.step('The same link works again', () async {
      await openPath(tester, invitationPath(contest.credentialOf(pilot)));
      await pumpUntilFound(tester, find.text('Hello, $pilot'));
      await tapVisible(tester, find.text('Continue as guest'));
      await pumpUntilFound(tester, find.text('2 rounds'));
    });
  });
  return pilotId;
}
