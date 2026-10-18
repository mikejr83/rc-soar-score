import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';
import 'support/open_settings.dart';

final _fairness = find.byKey(const ValueKey('fairness-score'));
final _toggle = find.byKey(const ValueKey('summary-toggle'));

Future<void> _openMatrix(WidgetTester tester) async {
  await openContest(tester, 'Front Range F5J Open');
  await tapRail(tester, 'Matrix');
  await pumpUntilFound(tester, _toggle);
}

Future<void> _resetPanels(WidgetTester tester) async {
  await openSettings(tester);
  await tapVisible(tester, find.byKey(const ValueKey('reset-areas-button')));
  await pumpUntilFound(tester, find.text('Panels are back to their defaults.'));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a hidden matrix summary stays hidden until reset', (
    tester,
  ) async {
    await openMainPage(tester);
    // The choice lives in the client's UI store, which a demo reset does not
    // clear, so start from the defaults.
    await _resetPanels(tester);

    await tapRail(tester, 'Contests');
    await _openMatrix(tester);
    expect(_fairness, findsOneWidget);
    expect(find.text('Hide summary'), findsOneWidget);

    await tapVisible(tester, _toggle);
    expect(_fairness, findsNothing);
    expect(find.text('Show summary'), findsOneWidget);

    // Leave the contest and come back: the summary is still hidden.
    await tapVisible(tester, find.byKey(const ValueKey('breadcrumb-contests')));
    await _openMatrix(tester);
    expect(_fairness, findsNothing);
    expect(find.text('Show summary'), findsOneWidget);

    // Resetting the panels on Settings brings the summary back.
    await _resetPanels(tester);
    await tapRail(tester, 'Contests');
    await _openMatrix(tester);
    expect(_fairness, findsOneWidget);
    expect(find.text('Hide summary'), findsOneWidget);
  });
}
