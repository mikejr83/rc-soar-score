import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/widgets/contest_shell.dart';
import 'package:soar_score_contest/widgets/contest_status_bar.dart';
import 'package:soar_score_contest/widgets/shell_header.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

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

    // The brand logo and the Create contest FAB sit at the top of the rail.
    expect(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.byType(BrandLogo),
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
