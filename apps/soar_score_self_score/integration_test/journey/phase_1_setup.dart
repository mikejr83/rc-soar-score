import 'package:flutter_test/flutter_test.dart';

import '../support/director_api.dart';
import '../support/launch_app.dart';
import 'journey.dart';

/// Phase 1: the director's side, through the API. The app starts on its home
/// page, and the contest, draw and invitation links exist.
Future<SeededContest> phase1Setup(WidgetTester tester, Journey journey) async {
  late SeededContest contest;
  await journey.phase(1, 'Set up the contest (API)', () async {
    await journey.step('Start the app', () async {
      await launchApp(tester);
      await tester.pump(const Duration(seconds: 1));
    });
    await journey.step(
      'Create an F5J contest with 4 pilots, 2 groups, 2 rounds, scoring open',
      () async {
        contest = await seedContest();
      },
    );
    await journey.step('Every pilot has an invitation link', () async {
      expect(contest.links.keys, contest.pilotNames);
      for (final link in contest.links.values) {
        expect(Uri.parse(link).pathSegments.first, 'invitations');
        expect(Uri.parse(link).pathSegments.last.length, greaterThan(40));
      }
    });
  });
  return contest;
}
