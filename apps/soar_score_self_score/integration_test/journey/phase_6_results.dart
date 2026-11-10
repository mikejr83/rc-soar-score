import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/router.dart';

import '../support/director_api.dart';
import '../support/launch_app.dart';
import 'journey.dart';
import 'phase_2_invitation.dart';

/// Phase 6: group and overall results, and the director holding the overall
/// standings back while scores are checked.
Future<void> phase6Results(
  WidgetTester tester,
  Journey journey,
  SeededContest contest,
  String pilotId,
) async {
  final pilot = contest.pilotNames[0];
  final mate = contest.groupMates(pilot, 1).first;
  final group = groupResultsPath(contest.id, pilotId, '1');
  await journey.phase(6, 'Group and overall results', () async {
    await journey.step('The group lists everyone who flew with you', () async {
      await openPath(tester, group);
      await pumpUntilFound(tester, find.text('(you)'));
      expect(find.text(mate), findsOneWidget);
      expect(find.text('No score yet'), findsOneWidget);
    });
    await journey.step('A group mate\'s score shows after it is in', () async {
      await contest.scoreAsDirector(mate, 1, timeFlown: 420);
      await tapVisible(tester, find.text('Refresh'));
      await pumpUntilFound(tester, find.text(mate));
      expect(find.textContaining('Last refreshed:'), findsOneWidget);
      expect(find.text('No score yet'), findsNothing);
      expect(find.textContaining('7:00'), findsWidgets);
    });
    await journey.step('Overall results rank the scored pilots', () async {
      await tapVisible(
        tester,
        find.textContaining('Overall results as of round 1'),
      );
      await pumpUntilFound(tester, find.text('Place'));
      expect(find.text(pilot), findsWidgets);
      expect(find.text(mate), findsWidgets);
      expect(find.textContaining('Standings are held'), findsNothing);
    });
    await journey.step(
      'Overall results refresh without leaving the page',
      () async {
        await tapVisible(tester, find.text('Refresh'));
        await pumpUntilFound(tester, find.text('Place'));
        expect(find.textContaining('Last refreshed:'), findsOneWidget);
        expect(find.text(pilot), findsWidgets);
        expect(find.text(mate), findsWidgets);
      },
    );
    await journey.step('Hidden results hold the overall standings', () async {
      await contest.action('hideResults');
      await tapVisible(tester, find.text('Refresh'));
      await pumpUntilFound(tester, find.textContaining('Standings are held'));
      // The group results stay current while the standings are held.
      await openPath(tester, group);
      await pumpUntilFound(tester, find.text('(you)'));
      expect(find.text(mate), findsOneWidget);
      // A score changed now shows in the group while the hold stays on.
      await contest.scoreAsDirector(
        mate,
        1,
        timeFlown: 480,
        baseRevision: 1,
        mutation: 'director-change',
      );
      await openPath(tester, pilotPath(contest.id, pilotId));
      await openPath(tester, resultsPath(contest.id, asOfRound: 1));
      await pumpUntilFound(tester, find.textContaining('Standings are held'));
      await openPath(tester, group);
      await pumpUntilFound(tester, find.text('(you)'));
      expect(find.textContaining('8:00'), findsWidgets);
      expect(find.textContaining('7:00'), findsNothing);
    });
    await journey.step('Showing results again lifts the hold', () async {
      await contest.action('showResults');
      await openPath(tester, pilotPath(contest.id, pilotId));
      await openPath(tester, resultsPath(contest.id, asOfRound: 1));
      await pumpUntilFound(tester, find.text('Place'));
      expect(find.textContaining('Standings are held'), findsNothing);
    });
  });
}
