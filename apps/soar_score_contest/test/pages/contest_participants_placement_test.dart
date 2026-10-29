import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/participants_page_support.dart';

Finder _search() => find.descendant(
  of: find.byKey(const ValueKey('participant-search')),
  matching: find.byType(TextField),
);

/// Adds Pia Ward from the search menu and confirms the add dialog.
Future<void> _addPia(WidgetTester tester) async {
  await tester.enterText(_search(), 'pia');
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ListTile, 'Pia Ward'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('add-participant-confirm')));
  await tester.pumpAndSettle();
}

/// A pilot who joins a drawn contest goes to the last group of every round;
/// with no scores yet the director may redraw instead.
void main() {
  testWidgets('with no scores the add offers to redraw the matrix', (
    tester,
  ) async {
    final server = ParticipantsServer(
      state: LifecycleState.running,
      drawn: true,
    );
    await pumpParticipantsPage(tester, server);

    await tester.enterText(_search(), 'pia');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Pia Ward'));
    await tester.pumpAndSettle();
    expect(find.text('Add after the draw?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-participant-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Redraw the matrix with Pia Ward?'), findsOneWidget);
    expect(server.placements, isEmpty);
  });

  testWidgets('declining the redraw puts the pilot in every round', (
    tester,
  ) async {
    final server = ParticipantsServer(
      state: LifecycleState.running,
      drawn: true,
    );
    await pumpParticipantsPage(tester, server);
    await _addPia(tester);

    await tester.tap(find.byKey(const ValueKey('redraw-keep')));
    await tester.pumpAndSettle();

    expect(server.placements, [
      Id.parse(server.additions.single['id']! as String),
    ]);
    expect(find.text('Pia Ward is in every round'), findsOneWidget);
    // The pilot has a number now, so nothing says they are unplaced.
    expect(find.text('Pia Ward isn’t placed yet'), findsNothing);
  });

  testWidgets('accepting the redraw opens the Matrix page and places nobody', (
    tester,
  ) async {
    final server = ParticipantsServer(
      state: LifecycleState.running,
      drawn: true,
    );
    await pumpParticipantsPage(tester, server);
    await _addPia(tester);

    await tester.tap(find.byKey(const ValueKey('redraw-with')));
    await tester.pumpAndSettle();

    expect(find.text('Matrix stub'), findsOneWidget);
    expect(server.placements, isEmpty);
  });

  testWidgets('with scores the pilot is placed without an offer, and a '
      'scored round says they got a zero', (tester) async {
    final server =
        ParticipantsServer(
            state: LifecycleState.running,
            drawn: true,
            withScores: true,
          )
          ..placementRounds = [
            {'round': 1, 'group': 2, 'lane': null, 'zeroed': true},
            {'round': 2, 'group': 2, 'lane': null, 'zeroed': false},
          ];
    await pumpParticipantsPage(tester, server);
    await _addPia(tester);

    expect(find.textContaining('Redraw the matrix'), findsNothing);
    expect(server.placements, hasLength(1));
    expect(find.text('Pia Ward is in every round'), findsOneWidget);
    expect(
      find.textContaining('Round 1 was already scored, so they got a zero'),
      findsOneWidget,
    );
  });

  testWidgets('a round no group can take the pilot in is reported', (
    tester,
  ) async {
    final server =
        ParticipantsServer(
            state: LifecycleState.running,
            drawn: true,
            withScores: true,
          )
          ..placementRounds = [
            {'round': 1, 'group': 2, 'lane': null, 'zeroed': false},
            {'round': 2, 'skipped_reason': 'group 2 has no open spot'},
          ];
    await pumpParticipantsPage(tester, server);
    await _addPia(tester);

    expect(find.text('Pia Ward is not in every round'), findsOneWidget);
    expect(
      find.textContaining('Round 2: group 2 has no open spot.'),
      findsOneWidget,
    );
    expect(find.text('Open Matrix'), findsWidgets);
  });

  testWidgets('a placement that fails leaves the pilot in the contest', (
    tester,
  ) async {
    final server = ParticipantsServer(
      state: LifecycleState.running,
      drawn: true,
      withScores: true,
    )..placementFailure = 409;
    await pumpParticipantsPage(tester, server);
    await _addPia(tester);

    expect(find.text('Pia Ward'), findsOneWidget);
    expect(find.textContaining('not in the rounds yet'), findsOneWidget);
  });

  testWidgets('the unplaced banner can place the pilot again', (tester) async {
    final server = ParticipantsServer(
      state: LifecycleState.running,
      drawn: true,
      withScores: true,
    )..placementFailure = 409;
    await pumpParticipantsPage(tester, server);
    await _addPia(tester);
    expect(server.placements, isEmpty);

    server.placementFailure = null;
    await tester.tap(find.text('Place in all rounds'));
    await tester.pumpAndSettle();

    expect(server.placements, hasLength(1));
    expect(find.text('Pia Ward is in every round'), findsOneWidget);
  });

  testWidgets('before the draw nothing is placed', (tester) async {
    final server = ParticipantsServer();
    await pumpParticipantsPage(tester, server);
    await _addPia(tester);

    expect(server.placements, isEmpty);
    expect(find.textContaining('Redraw the matrix'), findsNothing);
  });

  testWidgets('a non-flier who becomes a pilot after the draw is placed', (
    tester,
  ) async {
    final server = ParticipantsServer(
      state: LifecycleState.running,
      drawn: true,
      withScores: true,
    );
    await pumpParticipantsPage(tester, server);

    // Gary Novak (person 5) is a helper.
    await tester.tap(
      find.byKey(ValueKey('role-${personParticipationId(5).value}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilot').last);
    await tester.pumpAndSettle();
    // A pilot needs a class.
    await tester.enterText(
      find.descendant(
        of: find.byKey(ValueKey('class-${personParticipationId(5).value}')),
        matching: find.byType(TextField),
      ),
      'Open',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-participants')));
    await tester.pumpAndSettle();

    expect(server.placements, [personParticipationId(5)]);
    expect(find.text('Gary Novak is in every round'), findsOneWidget);
  });
}
