import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_contest/widgets/contest_shell.dart';
import 'package:soar_score_contest/widgets/contest_status_bar.dart';

class _LandingStub extends StatelessWidget {
  const _LandingStub();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Landing stub'));
}

/// Finds the "Landing" crumb inside the AppBar (the rail also renders a
/// "Landing" destination label).
Finder _landingCrumb(WidgetTester tester) =>
    find.descendant(of: find.byType(AppBar), matching: find.text('Landing'));

/// Builds a shell router with the landing route plus an extra nested route
/// (a test-local stand-in for a future ticket's page), so the breadcrumb and
/// back-arrow behavior of [ContestShell] can be exercised.
GoRouter _buildShellRouter() {
  return GoRouter(
    initialLocation: '/contest-administration',
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            ContestShell(state: state, child: child),
        routes: [
          GoRoute(
            path: '/contest-administration',
            name: 'landing',
            builder: (context, state) => const _LandingStub(),
          ),
          GoRoute(
            path: '/contest-administration/home',
            name: 'home',
            builder: (context, state) => const Text('Home content'),
          ),
        ],
      ),
    ],
  );
}

void main() {
  testWidgets('shell renders the rail, status bar and landing crumb', (
    tester,
  ) async {
    final router = _buildShellRouter();

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

    // The "Landing" crumb appears on the landing page; the back arrow does
    // not (it is a no-op on the root).
    expect(_landingCrumb(tester), findsOneWidget);
    expect(find.byKey(const ValueKey('breadcrumb-back')), findsNothing);

    // The "Landing" rail destination (index 0) is selected on the landing
    // page.
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.selectedIndex, 0);
    expect((rail.destinations.first.label as Text).data, 'Landing');
  });

  testWidgets('deeper routes show the back arrow and breadcrumb crumbs; '
      'back returns to the landing page', (tester) async {
    final router = _buildShellRouter();

    await tester.pumpWidget(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(_LandingStub), findsOneWidget);

    // Navigate to the nested route the way the landing page's "Continue
    // offline" flow does (`pushNamed`, ticket 022's flow). This creates a
    // real back entry behind the new page on every platform, so the
    // breadcrumb's back control can pop it.
    router.pushNamed('home');
    await tester.pumpAndSettle();

    expect(find.text('Home content'), findsOneWidget);
    expect(router.canPop(), isTrue);

    // The breadcrumb on a deeper route shows the back arrow, the "Landing"
    // crumb and the "home" segment crumb.
    expect(find.byKey(const ValueKey('breadcrumb-back')), findsOneWidget);
    expect(_landingCrumb(tester), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    // The shell received the deeper location.
    final shell = tester.widget<ContestShell>(find.byType(ContestShell));
    expect(shell.state.uri.path, '/contest-administration/home');

    // Tapping the back arrow returns to the landing page.
    await tester.tap(find.byKey(const ValueKey('breadcrumb-back')));
    await tester.pumpAndSettle();
    expect(find.byType(_LandingStub), findsOneWidget);
    expect(find.text('Home content'), findsNothing);
    final shellAfterBack = tester.widget<ContestShell>(
      find.byType(ContestShell),
    );
    expect(shellAfterBack.state.uri.path, '/contest-administration');
  });

  testWidgets('unwired rail destinations show the not-wired-up dialog', (
    tester,
  ) async {
    final router = _buildShellRouter();

    await tester.pumpWidget(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Contests'), findsOneWidget);
    await tester.tap(find.text('Contests'));
    await tester.pumpAndSettle();

    expect(find.text('Contests is not available yet'), findsOneWidget);
    expect(
      find.text(
        'Authentication through the identity provider has not been '
        'wired up yet. Please check back soon.',
      ),
      findsOneWidget,
    );

    // Tapping "OK" closes the dialog and keeps the user on the landing page.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(_LandingStub), findsOneWidget);
  });
}
