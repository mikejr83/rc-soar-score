import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';

final _drawButton = find.byKey(const ValueKey('draw-button'));
final _fairness = find.byKey(const ValueKey('fairness-score'));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a matrix is shown for a drawn contest and drawn for an undrawn '
      'one', (tester) async {
    await openMainPage(tester);

    // "Front Range F5J Open" arrives drawn: the grid and fairness score show
    // and there is nothing left to draw (redrawing is not built yet, #264).
    await openContest(tester, 'Front Range F5J Open');
    await tapRail(tester, 'Matrix');
    await pumpUntilFound(tester, _fairness);
    expect(find.text('Round 1'), findsOneWidget);
    expect(find.text('Group A'), findsWidgets);
    expect(_drawButton, findsNothing);
    expect(find.text('No matrix drawn yet'), findsNothing);

    // "Club Thermal Fun Fly" has its six pilots but no matrix yet.
    // The contest rail has no Contests entry, so use the header breadcrumb.
    await tapVisible(tester, find.byKey(const ValueKey('breadcrumb-contests')));
    await openContest(tester, 'Club Thermal Fun Fly');
    await tapRail(tester, 'Matrix');
    await pumpUntilFound(tester, find.text('No matrix drawn yet'));
    expect(_fairness, findsNothing);

    await enterIn(tester, find.byKey(const ValueKey('draw-rounds')), '3');
    await enterIn(tester, find.byKey(const ValueKey('draw-groups')), '2');
    // Six pilots in two groups.
    await pumpUntilFound(tester, find.text('2 groups: 3, 3 pilots'));

    await tapVisible(tester, _drawButton);
    await pumpUntilFound(tester, find.text('Draw the matrix?'));
    // Scoped to the dialog: the matrix page behind it shows the same counts.
    Finder inDialog(String text) => find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text(text),
    );
    expect(inDialog('6 scoring pilots'), findsOneWidget);
    expect(inDialog('3 rounds'), findsOneWidget);
    expect(inDialog('2 groups per round (3, 3 pilots)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('confirm-draw')));
    await pumpUntilFound(tester, _fairness);

    // The drawn matrix: three rounds, the fairness score, no draw form.
    expect(find.text('Round 1'), findsOneWidget);
    expect(find.text('Round 2'), findsOneWidget);
    expect(find.text('Round 3'), findsOneWidget);
    expect(find.text('Round 4'), findsNothing);
    expect(find.text('Group A'), findsWidgets);
    expect(find.text('Group B'), findsWidgets);
    expect(find.text('No matrix drawn yet'), findsNothing);
    expect(_drawButton, findsNothing);
  });
}
