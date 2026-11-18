import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scoring_test_support.dart';

const _flight = {'time_flown': 540, 'launch_height': 120};

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _openHistory(WidgetTester tester, int pilot) async {
  await tester.tap(_key('row-menu-${scoringAssignmentId(1, pilot).value}'));
  await tester.pumpAndSettle();
  await tester.tap(_key('menu-history'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an automatic score says so and offers Confirm', (tester) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()
      ..seedAutomaticScore(first, _flight)
      ..seedScore(scoringAssignmentId(1, 2), _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    // Only the automatic row has the chip and the button; a director's score
    // stays plain Official.
    expect(find.text('Accepted automatically'), findsOneWidget);
    expect(find.text('Official'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(_key('score-confirm-automatic-${first.value}'), findsOneWidget);
    expect(_key('score-automatic-note-${first.value}'), findsOneWidget);
  });

  testWidgets('Confirm sends the official score and ends as Official', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()..seedAutomaticScore(first, _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await tester.tap(_key('score-confirm-automatic-${first.value}'));
    await tester.pumpAndSettle();

    // No second version is entered; only the decision is sent.
    expect(server.entries, isEmpty);
    expect(server.confirmedAssignments, [first]);
    expect(server.promotedBodies.single['expected_score_revision'], 1);
    expect(find.text('Accepted automatically'), findsNothing);
    expect(find.text('Official'), findsOneWidget);
    expect(find.text('Confirm'), findsNothing);
  });

  testWidgets('a busy server shows Retry for Confirm, which asks again', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()..seedAutomaticScore(first, _flight);
    server.promoteFailures[first] = (503, 'contest_busy');
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await tester.tap(_key('score-confirm-automatic-${first.value}'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Not confirmed.'), findsOneWidget);
    // Nothing was stored; the row is still waiting for a decision.
    expect(find.text('Accepted automatically'), findsOneWidget);

    server.promoteFailures.clear();
    await tester.tap(_key('score-retry'));
    await tester.pumpAndSettle();

    expect(server.confirmedAssignments, [first]);
    expect(find.text('Accepted automatically'), findsNothing);
  });

  testWidgets(
    'a score corrected meanwhile shows the newer score, with nothing to confirm',
    (tester) async {
      final first = scoringAssignmentId(1, 1);
      final server = ScoringServer()..seedAutomaticScore(first, _flight);
      await pumpScoringPage(tester, server, round: 1, group: 1);
      // Another director corrects the score before the tap arrives.
      server.seedCorrection(first, {'time_flown': 500}, 'Timer misread');

      await tester.tap(_key('score-confirm-automatic-${first.value}'));
      await tester.pumpAndSettle();

      // The row now shows the newer, director-entered score and has nothing
      // left to confirm.
      expect(find.text('8:20'), findsWidgets);
      expect(find.text('Accepted automatically'), findsNothing);
      expect(find.text('Confirm'), findsNothing);
      expect(server.confirmedAssignments, isEmpty);
    },
  );

  testWidgets('typed edits turn Confirm off and say what to do', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()..seedAutomaticScore(first, _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await tester.tap(_key('score-row-${first.value}'));
    await tester.pumpAndSettle();
    await tester.enterText(_key('score-height-${first.value}'), '99');
    await tester.pumpAndSettle();

    final button = tester.widget<OutlinedButton>(
      _key('score-confirm-automatic-${first.value}'),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Save or revert your edits first.'), findsOneWidget);
  });

  testWidgets('history names the system, and the confirmation', (tester) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()..seedAutomaticScore(first, _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await _openHistory(tester, 1);
    expect(find.text('Made official by System (automatic)'), findsOneWidget);
    expect(find.text('Confirmed by the director'), findsNothing);
    await tester.tap(_key('score-history-close'));
    await tester.pumpAndSettle();

    await tester.tap(_key('score-confirm-automatic-${first.value}'));
    await tester.pumpAndSettle();
    await _openHistory(tester, 1);
    expect(find.text('Made official by System (automatic)'), findsOneWidget);
    expect(find.text('Confirmed by the director'), findsOneWidget);
  });

  testWidgets('a director\'s own score shows no automatic wording', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()..seedScore(first, _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    expect(find.text('Accepted automatically'), findsNothing);
    expect(find.text('Confirm'), findsNothing);
    await _openHistory(tester, 1);
    expect(find.textContaining('System (automatic)'), findsNothing);
  });
}
