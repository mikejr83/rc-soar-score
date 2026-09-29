import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/app.dart';
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
    expect(find.text('Manage and score RC sailplane soaring contests.'),
        findsOneWidget);
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
}
