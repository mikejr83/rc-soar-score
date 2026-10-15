import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/configuration_fields.dart';
import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';
import 'support/pump_until_gone.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scoring settings are edited and saved, and stay after leaving', (
    tester,
  ) async {
    await openMainPage(tester);
    await openContest(tester, 'Club Thermal Fun Fly');
    await openConfiguration(tester);
    final revision = savedRevision(tester);
    expect(find.text('Discard changes'), findsNothing);

    // Change one setting of each kind, always to the other value than the
    // demo data has, so the test does not depend on the seeded numbers.
    final rounding = segmentedValue(tester, 'rounding_mode');
    final newRounding = rounding == 'Round' ? 'Truncate' : 'Round';
    await tapSegment(tester, 'rounding_mode', newRounding);

    final decimals = segmentedValue(tester, 'decimal_places') as int;
    final newDecimals = (decimals + 1) % 4;
    await tapSegment(tester, 'decimal_places', '$newDecimals');

    final tiebreaker = toggleValue(tester, 'tiebreaker_enabled');
    await flipToggle(tester, 'tiebreaker_enabled');
    final classes = toggleValue(tester, 'classes_enabled');
    await flipToggle(tester, 'classes_enabled');

    // The save bar counts the four changes. A contest with no drawn matrix
    // and no scores has nothing to lose, so Save needs no confirmation.
    expect(find.text('4 unsaved changes'), findsOneWidget);
    await tapVisible(
      tester,
      find.widgetWithText(FilledButton, 'Save configuration'),
    );
    await pumpUntilFound(
      tester,
      find.text('Configuration revision ${revision + 1}'),
    );
    expect(find.text('Save configuration?'), findsNothing);
    expect(find.text('Discard changes'), findsNothing);

    // Leave the page and come back: the saved values are loaded again.
    await tapRail(tester, 'Workspace');
    await pumpUntilGone(tester, find.text('Scoring pilots'));
    await openConfiguration(tester);
    expect(savedRevision(tester), revision + 1);
    expect(segmentedValue(tester, 'rounding_mode'), newRounding);
    expect(segmentedValue(tester, 'decimal_places'), newDecimals);
    expect(toggleValue(tester, 'tiebreaker_enabled'), !tiebreaker);
    expect(toggleValue(tester, 'classes_enabled'), !classes);
    expect(find.text('Discard changes'), findsNothing);

    // Saving the configuration never draws the matrix.
    expect(find.text('Drawn and in sync'), findsNothing);
    await tapRail(tester, 'Matrix');
    await pumpUntilFound(tester, find.byKey(const ValueKey('draw-button')));
    expect(find.byKey(const ValueKey('fairness-score')), findsNothing);
  });
}
