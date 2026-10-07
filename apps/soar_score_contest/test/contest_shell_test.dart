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
      'Landings',
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

  testWidgets('Roles and Landings open their stub pages; the Create contest '
      'FAB opens the New Contest wizard', (tester) async {
    final router = buildShellTestRouter();
    addTearDown(router.dispose);
    await pumpShellRouter(tester, router);

    await tester.tap(find.text('Roles'));
    await tester.pumpAndSettle();
    expect(find.text('Roles content'), findsOneWidget);
    expect(find.byKey(const ValueKey('breadcrumb-roles')), findsOneWidget);
    expect(find.byKey(const ValueKey('new-role')), findsOneWidget);

    // New role opens the roles page with its name dialog requested.
    await tester.tap(find.byKey(const ValueKey('new-role')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ContestShell>(find.byType(ContestShell))
          .state
          .uri
          .toString(),
      newRolePath,
    );

    await tester.tap(find.text('Landings'));
    await tester.pumpAndSettle();
    expect(find.text('Landings content'), findsOneWidget);
    expect(find.byKey(const ValueKey('breadcrumb-landings')), findsOneWidget);
    expect(find.byKey(const ValueKey('new-landing')), findsOneWidget);

    await tester.tap(find.text('Contests'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create-contest')));
    await tester.pumpAndSettle();
    expect(find.text('New contest content'), findsOneWidget);

    // The wizard keeps Contests selected, has no FAB of its own and reads
    // `Contests > New contest` in the system scope.
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.selectedIndex, 0);
    expect(find.byKey(const ValueKey('create-contest')), findsNothing);
    expect(_contestsCrumb(), findsOneWidget);
    expect(find.text('New contest'), findsOneWidget);
    expect(find.byKey(const ValueKey('contest-title')), findsNothing);
    expect(find.byKey(const ValueKey('breadcrumb-back')), findsOneWidget);
  });

  testWidgets('on the participant page the FAB adds a participant', (
    tester,
  ) async {
    final router = buildShellTestRouter(initialLocation: participantsPath);
    addTearDown(router.dispose);
    await pumpShellRouter(tester, router);

    expect(find.byKey(const ValueKey('create-contest')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('add-participant')));
    await tester.pumpAndSettle();
    expect(find.text('Participant editor'), findsOneWidget);
  });

  testWidgets('the menu button expands the rail on wide windows and is '
      'absent on narrow ones', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = buildShellTestRouter();
    addTearDown(router.dispose);
    await pumpShellRouter(tester, router);

    NavigationRail rail() =>
        tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail().extended, isFalse);
    await tester.tap(find.byKey(const ValueKey('rail-toggle')));
    await tester.pumpAndSettle();
    expect(rail().extended, isTrue);
    expect(find.text('Create contest'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('rail-toggle')));
    await tester.pumpAndSettle();
    expect(rail().extended, isFalse);

    tester.view.physicalSize = const Size(834, 1194);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rail-toggle')), findsNothing);
  });

  testWidgets('the participant list is a top-level page titled '
      'Participants, without a back arrow', (tester) async {
    final router = buildShellTestRouter(initialLocation: participantsPath);
    addTearDown(router.dispose);
    await pumpShellRouter(tester, router);

    expect(find.text('Participants content'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('breadcrumb-participants')),
      findsOneWidget,
    );
    expect(_contestsCrumb(), findsNothing);
    expect(find.byKey(const ValueKey('breadcrumb-back')), findsNothing);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.selectedIndex, 1);
  });

  testWidgets('the participant editor has no back arrow; the Participants '
      'crumb returns to the list', (tester) async {
    final router = buildShellTestRouter(initialLocation: newParticipantPath);
    addTearDown(router.dispose);
    await pumpShellRouter(tester, router);

    expect(find.text('New'), findsOneWidget);
    expect(find.byKey(const ValueKey('breadcrumb-back')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('breadcrumb-participants')));
    await tester.pumpAndSettle();
    expect(find.text('Participants content'), findsOneWidget);
  });
}
