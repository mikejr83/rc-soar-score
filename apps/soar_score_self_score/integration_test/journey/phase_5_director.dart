import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/router.dart';

import '../support/director_api.dart';
import '../support/entry_form.dart';
import '../support/launch_app.dart';
import '../support/pilot_session.dart';
import 'journey.dart';
import 'phase_2_invitation.dart';

/// Phase 5: the director's official score wins over a pilot's own, whether
/// the pilot had already submitted or was still typing.
///
/// Leaves the first pilot signed in and returns their pilot id.
Future<String> phase5Director(
  WidgetTester tester,
  Journey journey,
  SeededContest contest,
  String secondPilotId,
) async {
  final first = contest.pilotNames[0];
  final second = contest.pilotNames[1];
  var firstPilotId = '';
  await journey.phase(5, 'The director scores too', () async {
    await journey.step('A score is entered while the form is open', () async {
      await openPath(tester, scoreEntryPath(contest.id, secondPilotId, '1'));
      await pumpUntilFound(tester, find.text('Time flown'));
      await fillEntry(tester);
      // The director's 8:20 lands before the pilot sends their 9:00.
      await contest.scoreAsDirector(second, 1, timeFlown: 500);
    });
    await journey.step(
      'The pilot\'s late submit does not replace it',
      () async {
        await tapVisible(tester, find.text('Submit score'));
        await pumpUntilFound(
          tester,
          find.textContaining('already has a score'),
        );
        expect(find.textContaining('stored score stands'), findsOneWidget);
        // The stored score is still the director's 8:20, read fresh.
        await openPath(
          tester,
          groupResultsPath(contest.id, secondPilotId, '1'),
        );
        await pumpUntilFound(tester, find.text('(you)'));
        expect(find.textContaining('8:20'), findsWidgets);
        expect(find.textContaining('9:00'), findsNothing);
      },
    );
    await journey.step('The overview shows the director\'s entry', () async {
      await openPath(tester, pilotPath(contest.id, secondPilotId));
      await pumpUntilFound(tester, find.text('2 rounds'));
      expect(find.textContaining('Entered by Director'), findsOneWidget);
    });
    await journey.step('An official score replaces a submitted one', () async {
      firstPilotId = await signInAs(tester, contest, first);
      await contest.scoreAsDirector(
        first,
        1,
        timeFlown: 500,
        baseRevision: 1,
        mutation: 'director-over',
      );
      await openPath(tester, groupResultsPath(contest.id, firstPilotId, '1'));
      await pumpUntilFound(tester, find.text('(you)'));
      expect(find.textContaining('8:20'), findsWidgets);
      expect(find.textContaining('9:00'), findsNothing);
    });
  });
  return firstPilotId;
}
