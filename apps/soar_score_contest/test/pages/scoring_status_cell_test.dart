import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scoring_test_support.dart';

const _flight = {'time_flown': 540, 'launch_height': 120};

Finder _key(String key) => find.byKey(ValueKey(key));

void main() {
  testWidgets('typed values say Unsaved once, with no second Not saved line', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()..seedScore(first, _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await tester.tap(_key('score-row-${first.value}'));
    await tester.pumpAndSettle();
    await tester.enterText(_key('score-height-${first.value}'), '99');
    await tester.pumpAndSettle();

    expect(find.text('Unsaved'), findsOneWidget);
    expect(find.text('Not saved yet'), findsNothing);
    expect(find.text('Not saved'), findsNothing);
    expect(find.text('Fix to save'), findsNothing);
  });

  testWidgets('a row left with a mistake says Fix to save', (tester) async {
    final first = scoringAssignmentId(1, 1);
    final second = scoringAssignmentId(1, 2);
    final server = ScoringServer()..seedScore(first, _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    await tester.tap(_key('score-row-${first.value}'));
    await tester.pumpAndSettle();
    await tester.enterText(_key('score-time-${first.value}'), '99:99');
    await tester.pumpAndSettle();
    // The open row lists its problems in its own band instead.
    expect(find.text('Fix to save'), findsNothing);

    await tester.tap(_key('score-row-${second.value}'));
    await tester.pumpAndSettle();

    expect(find.text('Fix to save'), findsOneWidget);
  });

  testWidgets('an unedited row has neither Unsaved nor Fix to save', (
    tester,
  ) async {
    final first = scoringAssignmentId(1, 1);
    final server = ScoringServer()..seedScore(first, _flight);
    await pumpScoringPage(tester, server, round: 1, group: 1);

    expect(find.text('Unsaved'), findsNothing);
    expect(find.text('Fix to save'), findsNothing);
  });
}
