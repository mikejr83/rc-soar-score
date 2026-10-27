import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';

final _drawButton = find.byKey(const ValueKey('draw-button'));
final _cancel = find.byKey(const ValueKey('cancel-draw'));
final _bar = find.byKey(const ValueKey('draw-progress-bar'));
final _fairness = find.byKey(const ValueKey('fairness-score'));

/// Fills the form of "Club Thermal Fun Fly" (six pilots, no matrix yet) and
/// confirms the draw.
Future<void> _startDraw(WidgetTester tester) async {
  await tapVisible(tester, _drawButton);
  await pumpUntilFound(tester, find.text('Draw the matrix?'));
  await tester.tap(find.byKey(const ValueKey('confirm-draw')));
}

/// A draw is held for a few seconds so the journey can look at it and cancel
/// it: the E2E builds use `DelayedDrawRunner` (`SOAR_SCORE_E2E_SLOW_DRAW` in
/// `scripts/e2e`, and always in the E2E test server).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a draw shows progress, can be cancelled, and then completes', (
    tester,
  ) async {
    await openMainPage(tester);
    await openContest(tester, 'Club Thermal Fun Fly');
    await tapRail(tester, 'Matrix');
    await pumpUntilFound(tester, find.text('No matrix drawn yet'));
    await enterIn(tester, find.byKey(const ValueKey('draw-rounds')), '3');
    await enterIn(tester, find.byKey(const ValueKey('draw-groups')), '2');
    await pumpUntilFound(tester, find.text('2 groups: 3, 3 pilots'));

    // Start: progress and Cancel appear, the Draw button is busy.
    await _startDraw(tester);
    await pumpUntilFound(tester, _bar);
    await pumpUntilFound(tester, find.textContaining('Drawing the matrix: '));
    expect(find.text('Drawing matrix…'), findsOneWidget);
    expect(_cancel, findsOneWidget);

    // Cancel: back to the form with the values kept, and nothing drawn.
    await tapVisible(tester, _cancel);
    await pumpUntilFound(
      tester,
      find.text('Draw cancelled. Nothing was changed.'),
    );
    await pumpUntilFound(tester, find.text('Draw matrix'));
    expect(_bar, findsNothing);
    expect(find.text('No matrix drawn yet'), findsOneWidget);
    expect(_fairness, findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('draw-rounds')))
          .controller!
          .text,
      '3',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('draw-groups')))
          .controller!
          .text,
      '2',
    );

    // Complete: draw again and let it finish.
    await _startDraw(tester);
    await pumpUntilFound(tester, _bar);
    await pumpUntilFound(tester, _fairness);
    expect(find.text('Round 1'), findsOneWidget);
    expect(find.text('Round 3'), findsOneWidget);
    expect(_bar, findsNothing);
    expect(_drawButton, findsNothing);
  });
}
