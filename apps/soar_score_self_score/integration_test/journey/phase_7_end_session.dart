import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/router.dart';

import '../support/director_api.dart';
import '../support/launch_app.dart';
import '../support/pilot_session.dart';
import 'journey.dart';
import 'phase_2_invitation.dart';

/// Phase 7: the pilot ends the session. Pages of the contest stop showing
/// data, and the same link starts a new session with the scores intact.
///
/// Runs before the expiry phase: the E2E clock only moves forward.
Future<void> phase7EndSession(
  WidgetTester tester,
  Journey journey,
  SeededContest contest,
  String pilotId,
) async {
  final pilot = contest.pilotNames[0];
  await journey.phase(7, 'End the session', () async {
    await journey.step('End session returns to the start page', () async {
      await openPath(tester, pilotPath(contest.id, pilotId));
      await pumpUntilFound(tester, find.text('2 rounds'));
      await tester.tap(find.byTooltip('End session'));
      await pumpUntilFound(
        tester,
        find.text('Score your flights at the field'),
      );
      expect(find.byTooltip('End session'), findsNothing);
    });
    await journey.step('The pilot\'s pages show no data afterwards', () async {
      await openPath(tester, pilotPath(contest.id, pilotId));
      await pumpUntilFound(tester, find.text('Back to start'));
      expect(find.text('2 rounds'), findsNothing);
      expect(find.text(pilot), findsNothing);
      await openPath(tester, resultsPath(contest.id, asOfRound: 1));
      await pumpUntilFound(tester, find.text('Back to start'));
      expect(find.text('Place'), findsNothing);
    });
    await journey.step('The same link starts a new session', () async {
      await signInAs(tester, contest, pilot);
      expect(find.text('Submitted'), findsWidgets);
      expect(find.byType(IconButton), findsWidgets);
    });
  });
}
