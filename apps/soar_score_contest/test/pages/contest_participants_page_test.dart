import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/widgets/participants/participant_card.dart';
import 'package:soar_score_contest/widgets/participants/participants_table.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/participants_page_support.dart';

Finder _row(int n) =>
    find.byKey(ValueKey('row-${personParticipationId(n).value}'));

void main() {
  testWidgets('lists the people with a count line and Save off', (
    tester,
  ) async {
    await pumpParticipantsPage(tester, ParticipantsServer());

    expect(tester.takeException(), isNull);
    expect(find.byType(ParticipantsTable), findsOneWidget);
    expect(find.text('4 pilots, 2 non-flying'), findsOneWidget);
    expect(
      find.text('Teams, pilot numbers, classes and roles are on.'),
      findsOneWidget,
    );
    expect(find.text('Ann Lee'), findsOneWidget);
    expect(find.text('Gary Novak'), findsOneWidget);
    // Email shows as a status, never as an address.
    expect(find.textContaining('@'), findsNothing);
    // The Save control is always there, off, with its reason.
    final save = tester.widget<FilledButton>(
      find.byKey(const ValueKey('save-participants')),
    );
    expect(save.onPressed, isNull);
    expect(find.text('No changes to save.'), findsOneWidget);
  });

  testWidgets('before the draw numbers are provisional', (tester) async {
    await pumpParticipantsPage(tester, ParticipantsServer());

    expect(find.text('Pilot no. (provisional)'), findsOneWidget);
    expect(find.text('1 · provisional'), findsOneWidget);
  });

  testWidgets('after the draw the allocated number shows and Has flights marks '
      'a scored pilot', (tester) async {
    await pumpParticipantsPage(
      tester,
      ParticipantsServer(
        state: LifecycleState.running,
        drawn: true,
        withScores: true,
      ),
    );

    expect(find.text('Pilot no.'), findsOneWidget);
    expect(find.textContaining('provisional'), findsNothing);
    expect(
      find.byKey(ValueKey('flights-${personParticipationId(1).value}')),
      findsOneWidget,
    );
    expect(find.text('Has flights'), findsOneWidget);
  });

  testWidgets('fewer than 2 scoring pilots is an error banner', (tester) async {
    await pumpParticipantsPage(tester, ParticipantsServer(pilots: 1));

    expect(
      find.text('Add at least 2 scoring pilots before the draw.'),
      findsOneWidget,
    );
  });

  testWidgets('exactly 2 scoring pilots is a warning', (tester) async {
    await pumpParticipantsPage(tester, ParticipantsServer(pilots: 2));

    expect(
      find.text('With fewer than 3 pilots, use 1 group per round.'),
      findsOneWidget,
    );
  });

  testWidgets('a pilot with no class is listed, and does not block', (
    tester,
  ) async {
    await pumpParticipantsPage(tester, ParticipantsServer());

    expect(find.byKey(const ValueKey('banner-missing-class')), findsOneWidget);
    expect(find.text('1 participant needs a class'), findsOneWidget);
    expect(find.text('Di Park: enter a class'), findsOneWidget);
  });

  testWidgets('without optional options only Name, Email and Status show', (
    tester,
  ) async {
    await pumpParticipantsPage(tester, ParticipantsServer(options: const {}));

    expect(find.text('Role'), findsNothing);
    expect(find.text('Class *'), findsNothing);
    expect(find.text('Team'), findsNothing);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
  });

  testWidgets('narrow windows stack the rows as cards', (tester) async {
    await pumpParticipantsPage(
      tester,
      ParticipantsServer(),
      size: const Size(700, 1400),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ParticipantsTable), findsNothing);
    expect(find.byType(ParticipantCard), findsNWidgets(6));
  });

  testWidgets('a completed contest is read-only', (tester) async {
    await pumpParticipantsPage(
      tester,
      ParticipantsServer(state: LifecycleState.completed, drawn: true),
    );

    expect(
      find.text('This contest is completed. Participants can’t be changed.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('save-participants')), findsNothing);
    expect(find.byKey(const ValueKey('add-participant-new')), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    expect(_row(1), findsOneWidget);
  });

  testWidgets('a locked administration turns role, class and team off', (
    tester,
  ) async {
    await pumpParticipantsPage(
      tester,
      ParticipantsServer(
        state: LifecycleState.running,
        lock: AdminLock.locked,
        drawn: true,
      ),
    );

    expect(
      find.text('Administration is locked. Unlock to change.'),
      findsOneWidget,
    );
    final add = tester.widget<FilledButton>(
      find.byKey(const ValueKey('add-participant-new')),
    );
    expect(add.onPressed, isNull);
    final team = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(ValueKey('team-${personParticipationId(1).value}')),
        matching: find.byType(TextField),
      ),
    );
    expect(team.enabled, isFalse);
  });

  testWidgets('a load that fails can be retried', (tester) async {
    final server = ParticipantsServer()..readFailure = 500;
    await pumpParticipantsPage(tester, server);

    expect(find.text('The participants could not be loaded.'), findsOneWidget);
    server.readFailure = null;
    await tester.tap(find.byKey(const ValueKey('page-state-retry')));
    await tester.pumpAndSettle();
    expect(find.text('Ann Lee'), findsOneWidget);
  });

  testWidgets('the search field filters the list', (tester) async {
    await pumpParticipantsPage(tester, ParticipantsServer());

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('participant-search')),
        matching: find.byType(TextField),
      ),
      'harbor',
    );
    await tester.pumpAndSettle();
    expect(find.text('Bo Ray'), findsOneWidget);
    expect(find.text('Ann Lee'), findsNothing);
  });
}
