import 'dart:ui' show PointerDeviceKind;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/matrix_test_support.dart';
import '../support/scoring_test_support.dart';

const _flight = {'time_flown': 540, 'launch_height': 120};

Finder _key(String key) => find.byKey(ValueKey(key));

void main() {
  testWidgets('completed rows give the lock reason on hover and long press', (
    tester,
  ) async {
    final server = ScoringServer(
      contest: matrixContest(state: LifecycleState.completed),
    );
    await pumpScoringPage(tester, server, round: 1, group: 1);
    const reason = 'This contest is completed. Scores cannot be entered.';
    final message = find.text(reason);
    final locked = find.byTooltip(reason);
    expect(locked, findsNWidgets(2));
    expect(message, findsOneWidget);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(locked.first));
    await tester.pumpAndSettle();
    expect(message, findsNWidgets(2));
    await mouse.removePointer();
    await tester.pumpAndSettle();
    expect(message, findsOneWidget);

    await tester.longPress(locked.last);
    await tester.pump();
    expect(message, findsNWidgets(2));
  });

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
