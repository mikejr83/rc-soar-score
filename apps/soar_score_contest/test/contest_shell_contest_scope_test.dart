import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/widgets/contest_shell.dart';
import 'package:soar_score_contest/widgets/shell_header.dart';

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
      'Matrix',
      'Scoring',
      'Reports',
    ]);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.selectedIndex, 0);
    expect(find.byKey(const ValueKey('create-contest')), findsNothing);
  });

  testWidgets('the header shows the back arrow and the contest crumb; '
      'without an API client the contest name falls back', (tester) async {
    final router = buildShellTestRouter(initialLocation: workspace);
    addTearDown(router.dispose);
    await pumpShellRouter(tester, router);

    expect(find.byKey(const ValueKey('breadcrumb-back')), findsOneWidget);
    expect(find.byKey(const ValueKey('breadcrumb-contests')), findsOneWidget);
    expect(find.text(ShellHeader.contestFallback), findsOneWidget);
  });

  testWidgets('back with no history returns to the main page', (tester) async {
    final router = buildShellTestRouter(initialLocation: workspace);
    addTearDown(router.dispose);
    await pumpShellRouter(tester, router);
    expect(router.canPop(), isFalse);

    await tester.tap(find.byKey(const ValueKey('breadcrumb-back')));
    await tester.pumpAndSettle();

    expect(find.text('Home content'), findsOneWidget);
    final shell = tester.widget<ContestShell>(find.byType(ContestShell));
    expect(shell.state.uri.path, homePath);
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

  testWidgets('unwired contest destinations show the not-wired-up dialog', (
    tester,
  ) async {
    final router = buildShellTestRouter(initialLocation: workspace);
    addTearDown(router.dispose);
    await pumpShellRouter(tester, router);

    await tester.tap(find.text('Matrix'));
    await tester.pumpAndSettle();
    expect(find.text('Matrix is not available yet'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Contest workspace content'), findsOneWidget);
  });
}
