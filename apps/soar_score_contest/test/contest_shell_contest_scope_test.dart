import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/router.dart';

import 'support/shell_test_router.dart';

void main() {
  final workspace = contestWorkspacePath(testContestId);

  testWidgets('a contest route shows the contest destinations with the '
      'workspace selected and no Create contest FAB', (tester) async {
    final router = buildShellTestRouter(initialLocation: workspace);
    addTearDown(router.dispose);
    await pumpShellRouter(tester, router);

    expect(find.text('Contest workspace content'), findsOneWidget);
    expect(railLabels(tester), [
      'Workspace',
      'Configuration',
      'Participants',
      'Matrix',
      'Scoring',
      'Reports',
    ]);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.selectedIndex, 0);
    expect(find.byKey(const ValueKey('create-contest')), findsNothing);
  });

  testWidgets('the Contests crumb leaves the contest and restores the system '
      'destinations', (tester) async {
    final router = buildShellTestRouter(initialLocation: workspace);
    addTearDown(router.dispose);
    await pumpShellRouter(tester, router);

    await tester.tap(find.byKey(const ValueKey('breadcrumb-contests')));
    await tester.pumpAndSettle();

    expect(find.text('Home content'), findsOneWidget);
    expect(railLabels(tester), [
      'Contests',
      'Participants',
      'Roles',
      'Landings',
    ]);
  });
}
