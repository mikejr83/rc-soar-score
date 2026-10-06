import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/widgets/contest_shell.dart';
import 'package:soar_score_contest/widgets/contest_status_bar.dart';

class _LandingStub extends StatelessWidget {
  const _LandingStub();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Landing stub'));
}

/// Finds the "Contests" crumb inside the AppBar (the rail also renders a
/// "Contests" destination label).
Finder _contestsCrumb(WidgetTester tester) =>
    find.descendant(of: find.byType(AppBar), matching: find.text('Contests'));

/// Builds a router with the landing route outside the shell, and the main
/// page plus a nested route (a test-local stand-in for a future page) inside
/// it, so the breadcrumb and back-arrow behavior of [ContestShell] can be
/// exercised.
GoRouter _buildShellRouter({String initialLocation = homePath}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: landingPath,
        name: 'landing',
        builder: (context, state) => const _LandingStub(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            ContestShell(state: state, child: child),
        routes: [
          GoRoute(
            path: homePath,
            name: 'home',
            builder: (context, state) => const Text('Home content'),
            routes: [
              GoRoute(
                path: 'workspace',
                name: 'workspace',
                builder: (context, state) => const Text('Workspace content'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('shell renders the rail, status bar and contests crumb', (
    tester,
  ) async {
    final router = _buildShellRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ContestShell), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(ContestStatusBar), findsOneWidget);
    expect(find.text('Home content'), findsOneWidget);

    // The crumb appears on the main page; the back arrow does not.
    expect(_contestsCrumb(tester), findsOneWidget);
    expect(find.byKey(const ValueKey('breadcrumb-back')), findsNothing);

    // The "Contests" rail destination (index 0) is selected on the main page.
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.selectedIndex, 0);
    expect((rail.destinations.first.label as Text).data, 'Contests');
  });

  testWidgets('the landing page is outside the shell', (tester) async {
    final router = _buildShellRouter(initialLocation: landingPath);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(_LandingStub), findsOneWidget);
    expect(find.byType(ContestShell), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('deeper routes show the back arrow and breadcrumb crumbs; '
      'back returns to the main page', (tester) async {
    final router = _buildShellRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home content'), findsOneWidget);

    // `pushNamed` creates a real back entry behind the new page on every
    // platform, so the breadcrumb's back control can pop it.
    router.pushNamed('workspace');
    await tester.pumpAndSettle();

    expect(find.text('Workspace content'), findsOneWidget);
    expect(router.canPop(), isTrue);

    expect(find.byKey(const ValueKey('breadcrumb-back')), findsOneWidget);
    expect(_contestsCrumb(tester), findsOneWidget);
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

  testWidgets('unwired rail destinations show the not-wired-up dialog', (
    tester,
  ) async {
    final router = _buildShellRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Matrix'), findsOneWidget);
    await tester.tap(find.text('Matrix'));
    await tester.pumpAndSettle();

    expect(find.text('Matrix is not available yet'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Home content'), findsOneWidget);
  });
}
