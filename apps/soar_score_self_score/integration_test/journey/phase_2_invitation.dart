import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/router.dart';

import '../support/director_api.dart';
import '../support/launch_app.dart';
import 'journey.dart';

/// Opens [path] the way a followed link does.
Future<void> openPath(WidgetTester tester, String path) async {
  router.go(path);
  await tester.pump(const Duration(milliseconds: 300));
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
    await journey.step('The landing page defers sign in and sign up', () async {
      await openPath(tester, '/');
      await pumpUntilFound(
        tester,
        find.text('Score your flights at the field'),
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Sign in'))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Sign up'),
            )
            .onPressed,
        isNull,
      );
      expect(find.textContaining('coming in a future release'), findsOneWidget);
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
    await journey.step('Application info lists the legal links', () async {
      await tapVisible(tester, find.byIcon(Icons.more_vert));
      await pumpUntilFound(tester, find.text('Application info'));
      await tapVisible(tester, find.text('Application info'));
      await pumpUntilFound(tester, find.text('Licences in this app'));
      expect(find.text('Open source licences'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms'), findsOneWidget);
      await tapVisible(tester, find.byTooltip('Back'));
      await pumpUntilFound(tester, find.text('2 rounds'));
    });
    await journey.step('The same link works again', () async {
      await openPath(tester, invitationPath(contest.credentialOf(pilot)));
      await pumpUntilFound(tester, find.text('Hello, $pilot'));
      await tapVisible(tester, find.text('Continue as guest'));
      await pumpUntilFound(tester, find.text('2 rounds'));
    });
  });
  return pilotId;
}
