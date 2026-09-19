// Widget tests for the reusable participant (pilot) manager page.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_data/soar_score_data.dart';

import 'package:soar_score_contest/main.dart';
import 'package:soar_score_contest/pages/participants/participants_page.dart';

void main() {
  /// Wraps [child] with the repository and connectivity inherited widgets so
  /// that [ParticipantsPage] can resolve its dependencies in a test.
  Widget harness(Widget child, {PilotRepository? repository}) {
    return PilotRepositoryWidget(
      repository: repository ?? InMemoryPilotRepository(),
      child: MaterialApp(
        home: child,
      ),
    );
  }

  Pilot pilot(String id, String first, String last, {String? email}) {
    return Pilot(
      id: id,
      firstName: first,
      lastName: last,
      email: email,
    );
  }

  group('ParticipantsPage', () {
    testWidgets('Shows the empty state when no participants exist',
        (tester) async {
      final repo = InMemoryPilotRepository();
      await tester.pumpWidget(harness(const ParticipantsPage(), repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('No participants yet.'), findsOneWidget);
      expect(find.text('Add a participant to get started.'), findsOneWidget);
      expect(find.byTooltip('Add participant'), findsOneWidget);
    });

    testWidgets('Lists participants from the repository', (tester) async {
      final repo = InMemoryPilotRepository();
      await repo.savePilot(pilot('1', 'Ada', 'Lovelace', email: 'ada@example.com'));
      await repo.savePilot(pilot('2', 'Grace', 'Hopper', email: 'grace@example.com'));

      await tester.pumpWidget(harness(const ParticipantsPage(), repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('Grace Hopper'), findsOneWidget);
    });

    testWidgets('Selecting a participant shows the action bar for it',
        (tester) async {
      final repo = InMemoryPilotRepository();
      await repo.savePilot(pilot('1', 'Ada', 'Lovelace'));

      await tester.pumpWidget(harness(const ParticipantsPage(), repository: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ada Lovelace'));
      await tester.pumpAndSettle();

      expect(find.text('Edit selected'), findsOneWidget);
      expect(find.text('Delete selected'), findsOneWidget);
      expect(find.text('Selected: Ada Lovelace'), findsOneWidget);
    });

    testWidgets('Add participant opens the editor bottom sheet',
        (tester) async {
      final repo = InMemoryPilotRepository();
      await tester.pumpWidget(harness(const ParticipantsPage(), repository: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add participant'));
      await tester.pumpAndSettle();

      expect(find.text('Add participant'), findsNWidgets(2)); // FAB + sheet title
      expect(find.text('First name *'), findsOneWidget);
      expect(find.text('Email (private) *'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Saving a new participant persists it and updates the list',
        (tester) async {
      final repo = InMemoryPilotRepository();
      await tester.pumpWidget(harness(const ParticipantsPage(), repository: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add participant'));
      await tester.pumpAndSettle();

      final fields = find.byType(EditableText);
      // Fields in order: first name, last name, email, then the optional ones.
      await tester.enterText(fields.at(0), 'Marie');
      await tester.enterText(fields.at(1), 'Curie');
      await tester.enterText(fields.at(2), 'marie@example.com');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      // Dismiss the still-open editor sheet so the list assertion is clean.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Marie Curie'), findsOneWidget);

      final saved = await repo.getPilots();
      expect(saved, hasLength(1));
      expect(saved.first.firstName, 'Marie');
      expect(saved.first.lastName, 'Curie');
    });
  });
}