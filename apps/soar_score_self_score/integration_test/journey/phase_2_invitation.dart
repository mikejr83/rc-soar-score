import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/router.dart';

import '../support/director_api.dart';
import '../support/launch_app.dart';
import 'journey.dart';

/// Opens [path] the way a followed link does. The test cannot reload the
/// browser, so it goes through the home page first: the invitation page keeps
/// the answer for the credential it opened with, and a real link is a fresh
/// page load.
///
/// Pass `via: null` for an ordinary page. Pass [via] when a guest session exists: the home page of a signed-in
/// visitor asks for contests, which the app cannot list yet (see #812), so the
/// bounce goes through a page of the session instead.
Future<void> openPath(
  WidgetTester tester,
  String path, {
  String? via = homePath,
}) async {
  if (via != null) {
    router.go(via);
    await tester.pump(const Duration(milliseconds: 300));
  }
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
    });
    await journey.step('The same link works again', () async {
      await openPath(
        tester,
        invitationPath(contest.credentialOf(pilot)),
        via: pilotPath(contest.id, pilotId),
      );
      await pumpUntilFound(tester, find.text('Hello, $pilot'));
      await tapVisible(tester, find.text('Continue as guest'));
      await pumpUntilFound(tester, find.text('2 rounds'));
    });
  });
  return pilotId;
}
