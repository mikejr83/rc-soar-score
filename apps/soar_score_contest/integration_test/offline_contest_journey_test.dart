import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:soar_score_contest/pages/home_page.dart';
import 'package:soar_score_contest/pages/landing_page.dart';

import 'support/launch_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('offline contest journey (native, demo database)', () {
    testWidgets('landing page leads to the contest list with demo contests', (
      tester,
    ) async {
      await launchApp(tester);

      expect(find.byType(LandingPage), findsOneWidget);
      await tester.tap(find.text('Continue offline'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Contests'), findsWidgets);
      expect(find.text('Autumn F5J Classic'), findsOneWidget);
    });

    testWidgets('opening a contest shows the contest scope rail', (
      tester,
    ) async {
      await launchApp(tester);
      await tester.tap(find.text('Continue offline'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.text('Autumn F5J Classic'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Contest scope shows the contest's own destinations.
      expect(find.text('Workspace'), findsWidgets);
      expect(find.text('Matrix'), findsWidgets);
      expect(find.byType(ListView), findsWidgets);
    });
  });
}
