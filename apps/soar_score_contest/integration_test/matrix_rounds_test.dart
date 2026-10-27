import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('add rounds and redraw the unscored rounds (#264)', (
    tester,
  ) async {
    await openMainPage(tester);

    // "Front Range F5J Open" arrives drawn, ready and without scores.
    await openContest(tester, 'Front Range F5J Open');
    await tapRail(tester, 'Matrix');
    await pumpUntilFound(tester, _key('fairness-score'));
    expect(find.text('Round 1'), findsOneWidget);
    expect(find.textContaining('later release'), findsNothing);

    // Add one round: the form is filled from the matrix and the grid grows.
    await tapVisible(tester, _key('add-rounds'));
    await pumpUntilFound(tester, _key('draw-rounds'));
    await enterIn(tester, _key('draw-rounds'), '1');
    await tapVisible(tester, _key('draw-button'));
    await pumpUntilFound(tester, _key('confirm-rounds'));
    await tester.tap(_key('confirm-rounds'));
    // The snackbar says it, and the page is back on the grid. (The new
    // column may be past the right edge of a narrow window, so the grid is
    // not searched for it.)
    await pumpUntilFound(tester, find.text('Rounds added.'));
    await pumpUntilFound(tester, _key('redraw-rounds'));
    expect(_key('draw-rounds'), findsNothing);

    // Nothing has scores, so the whole matrix can be redrawn.
    await tapVisible(tester, _key('redraw-rounds'));
    await pumpUntilFound(tester, _key('draw-rounds'));
    await tapVisible(tester, _key('draw-button'));
    await pumpUntilFound(tester, _key('confirm-rounds'));
    await tester.tap(_key('confirm-rounds'));
    await pumpUntilFound(tester, find.text('Rounds redrawn.'));
    await pumpUntilFound(tester, _key('fairness-score'));
    expect(find.text('Round 1'), findsOneWidget);
  });
}
