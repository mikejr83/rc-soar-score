// Widget tests for the contest administration home (contest-selection) page.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:soar_score_contest/pages/home_page.dart';

void main() {
  group('HomePage', () {
    Widget buildHomePage() => const MaterialApp(home: HomePage());

    testWidgets('Shows the empty contest state when no contests exist',
        (tester) async {
      await tester.pumpWidget(buildHomePage());

      expect(find.text('No contests yet.'), findsOneWidget);
      expect(find.text('Create a contest to get started.'), findsOneWidget);
    });

    testWidgets('Shows the action bar controls', (tester) async {
      await tester.pumpWidget(buildHomePage());

      expect(find.text('Create contest'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Participants'), findsOneWidget);
      expect(find.text('Roles'), findsOneWidget);
      expect(find.text('Landing bonuses'), findsOneWidget);
    });

    testWidgets('Create contest shows a "not wired up" dialog',
        (tester) async {
      await tester.pumpWidget(buildHomePage());

      await tester.tap(find.text('Create contest'));
      await tester.pumpAndSettle();

      expect(find.text('Create contest is not available yet'), findsOneWidget);
    });
  });
}