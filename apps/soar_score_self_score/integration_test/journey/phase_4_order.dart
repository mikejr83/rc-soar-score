import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/router.dart';

import '../support/director_api.dart';
import '../support/entry_form.dart';
import '../support/launch_app.dart';
import '../support/pilot_session.dart';
import 'journey.dart';
import 'phase_2_invitation.dart';

/// Phase 4: rounds open in order. A second pilot cannot score round 2 first,
/// not from the overview and not by going to the address.
///
/// Returns the second pilot's id.
Future<String> phase4Order(
  WidgetTester tester,
  Journey journey,
  SeededContest contest,
) async {
  final pilot = contest.pilotNames[1];
  var pilotId = '';
  await journey.phase(4, 'Rounds open in order', () async {
    await journey.step('Round 2 waits for round 1', () async {
      pilotId = await signInAs(tester, contest, pilot);
      expect(find.text('Next to score'), findsOneWidget);
      expect(find.text('Not open yet'), findsOneWidget);
      expect(find.textContaining('Score round 1 first'), findsOneWidget);
      // Only round 1 offers Enter.
      expect(find.text('Enter'), findsOneWidget);
    });
    await journey.step('Round 2 by address is refused by the server', () async {
      await openPath(tester, scoreEntryPath(contest.id, pilotId, '2'));
      await pumpUntilFound(tester, find.text('Time flown'));
      await fillEntry(tester);
      await tapVisible(tester, find.text('Submit score'));
      // The message sits in the lazily built list, so scroll to it.
      await tester.pump(const Duration(seconds: 2));
      final refusal = find.text('Score the earlier round first.');
      await scrollTo(tester, refusal);
      expect(refusal, findsOneWidget);
      expect(find.textContaining('Score: '), findsNothing);
    });
    await journey.step('Nothing was stored for either round', () async {
      await openPath(tester, pilotPath(contest.id, pilotId));
      await pumpUntilFound(tester, find.text('2 rounds'));
      expect(find.text('Submitted'), findsNothing);
      expect(find.text('Next to score'), findsOneWidget);
    });
  });
  return pilotId;
}
