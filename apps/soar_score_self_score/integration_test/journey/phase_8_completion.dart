import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/router.dart';

import '../support/director_api.dart';
import '../support/entry_form.dart';
import '../support/launch_app.dart';
import '../support/pilot_session.dart';
import 'journey.dart';
import 'phase_2_invitation.dart';

/// Phase 8: the contest is completed. The link keeps working for 24 hours,
/// read-only, then the session and the link both stop. The last phase: the
/// E2E server's invitation clock cannot be set back.
Future<void> phase8Completion(
  WidgetTester tester,
  Journey journey,
  SeededContest contest,
  String pilotId,
) async {
  final pilot = contest.pilotNames[0];
  await journey.phase(8, 'Completion and link expiry', () async {
    await journey.step('A completed contest takes no more scores', () async {
      await contest.action('complete');
      final state = await contest.api.call('GET', '/contests/${contest.id}');
      expect(state['lifecycle_state'], 'Completed');
      // Leave and come back, so the overview asks the API again.
      // (A page under the one just left keeps its state, so leave sideways.)
      await openPath(tester, resultsPath(contest.id, asOfRound: 1));
      await pumpUntilFound(tester, find.text('Place'));
      await openPath(tester, pilotPath(contest.id, pilotId));
      await pumpUntilFound(tester, find.text('Contest completed'));
      expect(find.text('Contest completed'), findsOneWidget);
      expect(find.text('Enter'), findsNothing);
      expect(find.text('Submitted'), findsWidgets);
    });
    await journey.step('A late submit is refused and stores nothing', () async {
      // The form can still be reached by address; the server must refuse.
      await openPath(tester, scoreEntryPath(contest.id, pilotId, '2'));
      await pumpUntilFound(tester, find.text('Time flown'));
      await fillEntry(tester);
      await tapVisible(tester, find.text('Submit score'));
      await tester.pump(const Duration(seconds: 2));
      final refusal = find.textContaining('Scoring is closed for this flight');
      await scrollTo(tester, refusal);
      expect(refusal, findsOneWidget);
      expect(find.textContaining('Score: '), findsNothing);
      // Nothing was stored for round 2.
      await openPath(tester, resultsPath(contest.id, asOfRound: 1));
      await pumpUntilFound(tester, find.text('Place'));
      await openPath(tester, pilotPath(contest.id, pilotId));
      await pumpUntilFound(tester, find.text('Contest completed'));
      expect(find.text('Submitted'), findsOneWidget);
    });
    await journey.step('The link still opens within 24 hours', () async {
      await signInAs(tester, contest, pilot);
      expect(find.text('Contest completed'), findsOneWidget);
    });
    await journey.step('After 24 hours the session has ended', () async {
      await contest.advanceClock(25);
      await openPath(tester, groupResultsPath(contest.id, pilotId, '1'));
      // The server's session_invalid answer, not a generic load failure.
      await pumpUntilFound(
        tester,
        find.text('Your session has ended. Open your invitation link again.'),
      );
      expect(find.text('Back to start'), findsOneWidget);
      expect(find.text('(you)'), findsNothing);
    });
    await journey.step('After 24 hours the link does not work', () async {
      await openPath(tester, invitationPath(contest.credentialOf(pilot)));
      await pumpUntilFound(tester, find.text('This link does not work'));
      expect(find.text('Continue as guest'), findsNothing);
    });
  });
}
