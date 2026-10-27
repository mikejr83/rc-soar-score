import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/configuration_fields.dart';
import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';
import 'support/pump_until_gone.dart';

final _drawButton = find.byKey(const ValueKey('draw-button'));
final _fairness = find.byKey(const ValueKey('fairness-score'));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('back-to-back flights are on by default, can be turned off in '
      'the configuration, and the matrix still draws', (tester) async {
    await openMainPage(tester);
    await openContest(tester, 'Club Thermal Fun Fly');
    await openConfiguration(tester);

    // On by default (decision #78); turn it off and save.
    expect(toggleValue(tester, 'allow_back_to_back'), isTrue);
    await flipToggle(tester, 'allow_back_to_back');
    expect(find.text('1 unsaved change'), findsOneWidget);
    await tapVisible(
      tester,
      find.widgetWithText(FilledButton, 'Save configuration'),
    );
    await pumpUntilGone(tester, find.text('1 unsaved change'));

    // The saved value is loaded again after leaving the page.
    await tapRail(tester, 'Workspace');
    await pumpUntilGone(tester, find.text('Scoring pilots'));
    await openConfiguration(tester);
    expect(toggleValue(tester, 'allow_back_to_back'), isFalse);

    // The matrix page tells the director the draw will avoid them.
    await tapRail(tester, 'Matrix');
    await pumpUntilFound(tester, _drawButton);
    expect(find.text('Back-to-back flights'), findsOneWidget);
    expect(find.text('Avoided'), findsOneWidget);

    // Six pilots in three groups of two can avoid them, so the draw works.
    await enterIn(tester, find.byKey(const ValueKey('draw-rounds')), '4');
    await enterIn(tester, find.byKey(const ValueKey('draw-groups')), '3');
    await pumpUntilFound(tester, find.text('3 groups: 2, 2, 2 pilots'));
    await tapVisible(tester, _drawButton);
    await pumpUntilFound(tester, find.text('Draw the matrix?'));
    await tester.tap(find.byKey(const ValueKey('confirm-draw')));
    await pumpUntilFound(tester, _fairness);
    expect(find.text('Round 4'), findsOneWidget);
  });
}
