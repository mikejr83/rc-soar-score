import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/app.dart';
import 'package:soar_score_contest/app_mode_provider.dart';
import 'package:soar_score_contest/pages/home_page.dart';
import 'package:soar_score_contest/pages/landing_page.dart';

void main() {
  testWidgets('renders the contest-administration landing page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SoarScoreContestApp());
    await tester.pumpAndSettle();

    expect(find.byType(LandingPage), findsOneWidget);
    // The title appears in the AppBar and again as the page heading.
    expect(find.text(LandingPage.title), findsWidgets);
  });

  testWidgets('displays the shell structure with title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SoarScoreContestApp());
    await tester.pumpAndSettle();

    expect(find.text('RC Soar Score'), findsWidgets);
    expect(
      find.text('Manage and score RC sailplane soaring contests.'),
      findsOneWidget,
    );
  });

  testWidgets('displays sign in button', (WidgetTester tester) async {
    await tester.pumpWidget(const SoarScoreContestApp());
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('displays create account button', (WidgetTester tester) async {
    await tester.pumpWidget(const SoarScoreContestApp());
    await tester.pumpAndSettle();

    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('displays continue offline button', (WidgetTester tester) async {
    await tester.pumpWidget(const SoarScoreContestApp());
    await tester.pumpAndSettle();

    expect(find.text('Continue offline'), findsOneWidget);
    expect(
      find.text(
        'Offline contests stay on this device unless you publish them or sign '
        'in to enable synchronization.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'continue offline enables offline mode and opens the contest selection page',
    (WidgetTester tester) async {
      final appMode = AppModeNotifier();
      expect(appMode.isOfflineMode, isFalse);

      await tester.pumpWidget(SoarScoreContestApp(appMode: appMode));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue offline'));
      await tester.pumpAndSettle();

      expect(appMode.isOfflineMode, isTrue);
      expect(
        find.descendant(
          of: find.byType(HomePage),
          matching: find.text('Contests'),
        ),
        findsOneWidget,
      );
      expect(find.byType(HomePage), findsOneWidget);
    },
  );

  testWidgets('web landing page hides offline entry and messaging', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LandingPage(isWeb: true)));
    await tester.pumpAndSettle();

    expect(find.text('Continue offline'), findsNothing);
    expect(
      find.textContaining('Offline contests stay on this device'),
      findsNothing,
    );
  });

  testWidgets('displays help and public site links', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SoarScoreContestApp());
    await tester.pumpAndSettle();

    expect(find.text('Help'), findsOneWidget);
    expect(find.text('Public contest site'), findsOneWidget);
  });

  testWidgets('renders the theme with M3 components', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SoarScoreContestApp());
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('redirects unknown paths to the landing page (guard)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const SoarScoreContestApp(routerInitialLocation: '/nonexistent'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LandingPage), findsOneWidget);
  });

  testWidgets(
    'redirects routes beyond landing to landing page when not in offline mode',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const SoarScoreContestApp(
          routerInitialLocation: '/contest-administration/home',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LandingPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    },
  );

  testWidgets('allows routes beyond landing when in offline mode', (
    WidgetTester tester,
  ) async {
    final appMode = AppModeNotifier(isOfflineMode: true);
    await tester.pumpWidget(
      SoarScoreContestApp(
        appMode: appMode,
        routerInitialLocation: '/contest-administration/home',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(LandingPage), findsNothing);
  });
}
