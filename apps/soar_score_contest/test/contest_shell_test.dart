import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/pages/landing_page.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/widgets/contest_shell.dart';
import 'package:soar_score_contest/widgets/contest_status_bar.dart';
import 'package:soar_score_contest/widgets/shell_header.dart';

import 'support/shell_test_router.dart';

Finder _contestsCrumb() => find.byKey(const ValueKey('breadcrumb-contests'));

void main() {
  testWidgets('shell renders the rail, header, status bar and system '
      'destinations on the main page', (tester) async {
    final router = buildShellTestRouter();
    addTearDown(router.dispose);
    await pumpShellRouter(tester, router);

    expect(find.byType(ContestShell), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(ShellHeader), findsOneWidget);
    expect(find.byType(ContestStatusBar), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Home content'), findsOneWidget);

    // The crumb appears on the main page; the back arrow does not.
    expect(_contestsCrumb(), findsOneWidget);
    expect(find.byKey(const ValueKey('breadcrumb-back')), findsNothing);

    // System-level destinations only: contest tasks need a contest.
    expect(railLabels(tester), [
      'Contests',
      'Participants',
      'Roles',
      'Bonuses',
    ]);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.selectedIndex, 0);

    // The title and the Create contest FAB sit at the top of the rail.
    expect(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text(LandingPage.title),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('create-contest')), findsOneWidget);
  });

  testWidgets('the rail runs full height and the status bar spans the full '
      'window width', (tester) async {
    final router = buildShellTestRouter();
    addTearDown(router.dispose);
    await pumpShellRouter(tester, router);

    final window = tester.getSize(find.byType(ContestShell));
    final statusBar = tester.getRect(find.byType(ContestStatusBar));
    expect(statusBar.width, window.width);
    expect(statusBar.bottom, window.height);

    // Nothing sits above the rail: it starts at the top of the window and
    // ends at the status bar.
    final rail = tester.getRect(find.byType(NavigationRail));
    expect(rail.top, 0);
    expect(rail.bottom, statusBar.top);

    // The header spans the content pane only, not the rail.
    final header = tester.getRect(find.byType(ShellHeader));
    expect(header.left, greaterThanOrEqualTo(rail.right));
  });

  testWidgets('the landing page is outside the shell', (tester) async {
    final router = buildShellTestRouter(initialLocation: landingPath);
    addTearDown(router.dispose);
    await pumpShellRouter(tester, router);

    expect(find.byType(LandingStub), findsOneWidget);
    expect(find.byType(ContestShell), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('deeper routes show the back arrow and breadcrumb crumbs; '
      'back returns to the main page', (tester) async {
    final router = buildShellTestRouter();
    addTearDown(router.dispose);
    await pumpShellRouter(tester, router);
    expect(find.text('Home content'), findsOneWidget);

    // `pushNamed` creates a real back entry behind the new page on every
    // platform, so the breadcrumb's back control can pop it.
    router.pushNamed('workspace');
    await tester.pumpAndSettle();

    expect(find.text('Workspace content'), findsOneWidget);
    expect(router.canPop(), isTrue);

    expect(find.byKey(const ValueKey('breadcrumb-back')), findsOneWidget);
    expect(_contestsCrumb(), findsOneWidget);
    expect(find.text('Workspace'), findsOneWidget);

    final shell = tester.widget<ContestShell>(find.byType(ContestShell));
    expect(shell.state.uri.path, '$homePath/workspace');

    await tester.tap(find.byKey(const ValueKey('breadcrumb-back')));
    await tester.pumpAndSettle();
    expect(find.text('Home content'), findsOneWidget);
    expect(find.text('Workspace content'), findsNothing);
    final shellAfterBack = tester.widget<ContestShell>(
      find.byType(ContestShell),
    );
    expect(shellAfterBack.state.uri.path, homePath);
  });

  testWidgets('unwired rail destinations and the Create contest FAB show the '
      'not-wired-up dialog', (tester) async {
    final router = buildShellTestRouter();
    addTearDown(router.dispose);
    await pumpShellRouter(tester, router);

    await tester.tap(find.text('Participants'));
    await tester.pumpAndSettle();
    expect(find.text('Participants is not available yet'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Home content'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('create-contest')));
    await tester.pumpAndSettle();
    expect(find.text('Create contest is not available yet'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
