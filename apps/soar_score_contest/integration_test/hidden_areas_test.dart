import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';
import 'support/open_settings.dart';

final _fairness = find.byKey(const ValueKey('fairness-score'));
final _toggle = find.byKey(const ValueKey('summary-toggle'));
final _detailsToggle = find.byKey(const ValueKey('draw-details-toggle'));
final _details = find.text('Matrix revision');
final _advanced = find.byKey(const ValueKey('draw-seed'));
final _railToggle = find.byKey(const ValueKey('rail-toggle'));

NavigationRail _rail(WidgetTester tester) =>
    tester.widget<NavigationRail>(find.byType(NavigationRail));

Future<void> _resetPanels(WidgetTester tester) async {
  await openSettings(tester);
  await tapVisible(tester, find.byKey(const ValueKey('reset-areas-button')));
  await pumpUntilFound(tester, find.text('Panels are back to their defaults.'));
}

/// The drawn F5J contest.
Future<void> _openFrontRangeMatrix(WidgetTester tester) async {
  await openContest(tester, 'Front Range F5J Open');
  await tapRail(tester, 'Matrix');
  await pumpUntilFound(tester, _toggle);
}

Future<void> _backToContestList(WidgetTester tester) async =>
    tapVisible(tester, find.byKey(const ValueKey('breadcrumb-contests')));

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
    await _openFrontRangeMatrix(tester);
    expect(_fairness, findsOneWidget);
    expect(find.text('Hide summary'), findsOneWidget);

    await tapVisible(tester, _toggle);
    expect(_fairness, findsNothing);
    expect(find.text('Show summary'), findsOneWidget);

    // Leave the contest and come back: the summary is still hidden.
    await _backToContestList(tester);
    await _openFrontRangeMatrix(tester);
    expect(_fairness, findsNothing);
    expect(find.text('Show summary'), findsOneWidget);

    // Resetting the panels on Settings brings the summary back.
    await _resetPanels(tester);
    // Settings opened inside a contest keeps the contest rail, which has no
    // Contests entry, so go back through the breadcrumb.
    await _backToContestList(tester);
    await _openFrontRangeMatrix(tester);
    expect(_fairness, findsOneWidget);
    expect(find.text('Hide summary'), findsOneWidget);
  });

  testWidgets('shown draw details stay shown until reset', (tester) async {
    await openMainPage(tester);
    await _resetPanels(tester);

    await tapRail(tester, 'Contests');
    await _openFrontRangeMatrix(tester);
    expect(_details, findsNothing);

    await tapVisible(tester, _detailsToggle);
    expect(_details, findsOneWidget);

    await _backToContestList(tester);
    await _openFrontRangeMatrix(tester);
    expect(_details, findsOneWidget);

    await _resetPanels(tester);
    // Settings opened inside a contest keeps the contest rail, which has no
    // Contests entry, so go back through the breadcrumb.
    await _backToContestList(tester);
    await _openFrontRangeMatrix(tester);
    expect(_details, findsNothing);
  });

  testWidgets('an open Advanced section stays open until reset', (
    tester,
  ) async {
    await openMainPage(tester);
    await _resetPanels(tester);

    // The undrawn thermal contest shows the first-draw form, whose Advanced
    // section is collapsed by default.
    await tapRail(tester, 'Contests');
    await openContest(tester, 'Club Thermal Fun Fly');
    await tapRail(tester, 'Matrix');
    await pumpUntilFound(tester, find.text('No matrix drawn yet'));
    expect(_advanced, findsNothing);

    await tapVisible(tester, find.byType(ExpansionTile));
    expect(_advanced, findsOneWidget);

    await _backToContestList(tester);
    await openContest(tester, 'Club Thermal Fun Fly');
    await tapRail(tester, 'Matrix');
    await pumpUntilFound(tester, find.text('Random seed'));
    expect(_advanced, findsOneWidget);

    await _resetPanels(tester);
    // Settings opened inside a contest keeps the contest rail, which has no
    // Contests entry, so go back through the breadcrumb.
    await _backToContestList(tester);
    await openContest(tester, 'Club Thermal Fun Fly');
    await tapRail(tester, 'Matrix');
    await pumpUntilFound(tester, find.text('No matrix drawn yet'));
    expect(_advanced, findsNothing);
  });

  testWidgets('an expanded rail stays expanded until reset', (tester) async {
    await openMainPage(tester);
    await _resetPanels(tester);

    // The toggle only exists on wide windows; skip the check otherwise.
    if (_railToggle.evaluate().isEmpty) return;

    expect(_rail(tester).extended, isFalse);

    await tapVisible(tester, _railToggle);
    expect(_rail(tester).extended, isTrue);

    await _resetPanels(tester);
    expect(_rail(tester).extended, isFalse);
  });
}
