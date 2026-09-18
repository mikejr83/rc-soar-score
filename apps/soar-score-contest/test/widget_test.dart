// Widget tests for the contest administration application.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:soar_score_contest/main.dart';
import 'package:soar_score_contest/pages/landing_page.dart';

void main() {
  group('ScoreSoarContest', () {
    testWidgets('App starts on the landing page', (tester) async {
      await tester.pumpWidget(const ScoreSoarContest());

      expect(find.text('RC Soar Score'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
    });

    testWidgets('Development nav item opens the testing pages', (tester) async {
      await tester.pumpWidget(const ScoreSoarContest());

      await tester.tap(find.byTooltip('Development testing pages'));
      await tester.pumpAndSettle();

      expect(find.text('Scoring Tests'), findsOneWidget);
    });
  });

  group('LandingPage', () {
    Widget buildLandingPage() => const MaterialApp(home: LandingPage());

    testWidgets('Shows help and public site links as external navigation',
        (tester) async {
      await tester.pumpWidget(buildLandingPage());

      expect(find.text('Help'), findsOneWidget);
      expect(find.text('Public contest site'), findsOneWidget);
    });

    testWidgets('Sign in shows a "not wired up" dialog', (tester) async {
      await tester.pumpWidget(buildLandingPage());

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in is not available yet'), findsOneWidget);
      expect(
        find.text(
          'Authentication through the identity provider has not been '
          'wired up yet. Please check back soon.',
        ),
        findsOneWidget);
    });

    testWidgets('Create account shows a "not wired up" dialog',
        (tester) async {
      await tester.pumpWidget(buildLandingPage());

      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Create account is not available yet'), findsOneWidget);
    });

    testWidgets('Closing the dialog returns to the landing page',
        (tester) async {
      await tester.pumpWidget(buildLandingPage());

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('RC Soar Score'), findsOneWidget);
    });

    testWidgets('External link confirmation dialog offers Open and Cancel',
        (tester) async {
      await tester.pumpWidget(buildLandingPage());

      await tester.tap(find.text('Help'));
      await tester.pumpAndSettle();

      expect(find.text('Opening external site'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}