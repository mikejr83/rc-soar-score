import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/widgets/unsaved_changes_guard.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/participants_page_support.dart';

Finder _search() => find.descendant(
  of: find.byKey(const ValueKey('participant-search')),
  matching: find.byType(TextField),
);

Finder _check(int n) => find.descendant(
  of: find.byKey(ValueKey('row-${personParticipationId(n).value}')),
  matching: find.byType(Checkbox),
);

Future<void> _searchAndPick(
  WidgetTester tester,
  String text,
  String name,
) async {
  await tester.enterText(_search(), text);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ListTile, name));
  await tester.pumpAndSettle();
}

Finder _remove() => find.byKey(const ValueKey('remove-participants'));

void main() {
  group('adding', () {
    testWidgets('search offers saved profiles and marks people already in the '
        'contest', (tester) async {
      await pumpParticipantsPage(tester, ParticipantsServer());

      await tester.enterText(_search(), 'lee');
      await tester.pumpAndSettle();
      expect(find.text('Already in this contest'), findsOneWidget);

      await tester.enterText(_search(), 'ward');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'Pia Ward'), findsOneWidget);
    });

    testWidgets('adding before the draw asks for a role and adds at once', (
      tester,
    ) async {
      final server = ParticipantsServer();
      await pumpParticipantsPage(tester, server);

      await _searchAndPick(tester, 'pia', 'Pia Ward');
      expect(find.text('Add Pia Ward?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('add-participant-confirm')));
      await tester.pumpAndSettle();

      expect(server.additions, hasLength(1));
      expect(
        server.additions.single['participant_profile_id'],
        personProfileId(7).value,
      );
      expect(find.text('Pia Ward added to the contest.'), findsOneWidget);
      expect(find.text('Pia Ward'), findsOneWidget);
      // The new row is highlighted and numbered provisionally.
      expect(find.text('5 · provisional'), findsOneWidget);
    });

    testWidgets('after the draw a pilot is a late add, not placed yet', (
      tester,
    ) async {
      final server = ParticipantsServer(
        state: LifecycleState.running,
        drawn: true,
      );
      await pumpParticipantsPage(tester, server);

      await _searchAndPick(tester, 'pia', 'Pia Ward');
      expect(find.text('Add after the draw?'), findsOneWidget);
      expect(
        find.textContaining('The draw has already been made.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('add-participant-confirm')));
      await tester.pumpAndSettle();

      expect(
        find.text('Pia Ward added to the contest. Not placed yet.'),
        findsOneWidget,
      );
      expect(find.text('Not placed yet'), findsWidgets);
      expect(find.text('Pia Ward isn’t placed yet'), findsOneWidget);
    });

    testWidgets('a non-flying role chosen first skips the late-add warning', (
      tester,
    ) async {
      final server = ParticipantsServer(
        state: LifecycleState.running,
        drawn: true,
      );
      await pumpParticipantsPage(tester, server);

      await _searchAndPick(tester, 'pia', 'Pia Ward');
      await tester.tap(find.byKey(const ValueKey('add-participant-role')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Helper').last);
      await tester.pumpAndSettle();

      expect(find.text('Add Pia Ward?'), findsOneWidget);
      expect(find.textContaining('The draw has already'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('add-participant-confirm')));
      await tester.pumpAndSettle();

      expect(server.additions.single['role_id'], SystemRoles.helperId.value);
    });

    testWidgets('cancelling the dialog adds nobody', (tester) async {
      final server = ParticipantsServer();
      await pumpParticipantsPage(tester, server);

      await _searchAndPick(tester, 'pia', 'Pia Ward');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(server.additions, isEmpty);
    });

    testWidgets('a failed add can be tried again without duplicating', (
      tester,
    ) async {
      final server = ParticipantsServer()..addFailure = 500;
      await pumpParticipantsPage(tester, server);

      await _searchAndPick(tester, 'pia', 'Pia Ward');
      await tester.tap(find.byKey(const ValueKey('add-participant-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Couldn’t add Pia Ward'), findsOneWidget);

      server.addFailure = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      // Both requests carry the same id, so the server stores one person.
      expect(server.additions, hasLength(2));
      expect(server.additions.first['id'], server.additions.last['id']);
      expect(find.text('Pia Ward added to the contest.'), findsOneWidget);
      expect(find.text('Couldn’t add Pia Ward'), findsNothing);
    });

    testWidgets('a locked administration cannot add', (tester) async {
      await pumpParticipantsPage(
        tester,
        ParticipantsServer(
          state: LifecycleState.running,
          lock: AdminLock.locked,
          drawn: true,
        ),
      );

      await tester.enterText(_search(), 'pia');
      await tester.pumpAndSettle();

      // The field only filters: no saved profile is offered.
      expect(find.widgetWithText(ListTile, 'Pia Ward'), findsNothing);
    });
  });

  group('removing', () {
    testWidgets('Remove is off until someone is selected', (tester) async {
      await pumpParticipantsPage(tester, ParticipantsServer());

      expect(tester.widget<OutlinedButton>(_remove()).onPressed, isNull);

      await tester.tap(_check(5));
      await tester.pumpAndSettle();

      expect(tester.widget<OutlinedButton>(_remove()).onPressed, isNotNull);
      expect(find.text('Remove 1'), findsOneWidget);
    });

    testWidgets('the confirmation names the people; confirming removes them', (
      tester,
    ) async {
      final server = ParticipantsServer();
      await pumpParticipantsPage(tester, server);
      await tester.tap(_check(5));
      await tester.tap(_check(6));
      await tester.pumpAndSettle();

      await tester.tap(_remove());
      await tester.pumpAndSettle();
      expect(find.text('Remove 2 people from this contest?'), findsOneWidget);
      expect(find.text('Gary Novak'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('confirm-remove')));
      await tester.pumpAndSettle();

      expect(server.removals, [
        personParticipationId(5),
        personParticipationId(6),
      ]);
      expect(find.text('Gary Novak'), findsNothing);
      expect(
        find.text('Gary Novak and Eve Moss removed from the contest.'),
        findsOneWidget,
      );
    });

    testWidgets('a pilot with flights cannot be removed, and says why', (
      tester,
    ) async {
      await pumpParticipantsPage(
        tester,
        ParticipantsServer(
          state: LifecycleState.running,
          drawn: true,
          withScores: true,
        ),
      );

      await tester.tap(_check(1));
      await tester.pumpAndSettle();

      expect(tester.widget<OutlinedButton>(_remove()).onPressed, isNull);
      expect(find.byKey(const ValueKey('remove-reason')), findsOneWidget);
    });

    testWidgets('a removal the server refuses is reported as partial', (
      tester,
    ) async {
      final server = ParticipantsServer()
        ..removalRefused.add(personParticipationId(6));
      await pumpParticipantsPage(tester, server);
      await tester.tap(_check(5));
      await tester.tap(_check(6));
      await tester.pumpAndSettle();

      await tester.tap(_remove());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-remove')));
      await tester.pumpAndSettle();

      expect(find.text('1 of 2 removed'), findsOneWidget);
      expect(find.textContaining('Eve Moss wasn’t:'), findsOneWidget);
      expect(find.text('Eve Moss'), findsOneWidget);
    });
  });

  testWidgets('leaving with unsaved changes asks first', (tester) async {
    final guard = UnsavedChangesGuard();
    await pumpParticipantsPage(tester, ParticipantsServer(), guard: guard);
    expect(await guard.confirmLeave(), isTrue);

    await tester.enterText(
      find.descendant(
        of: find.byKey(ValueKey('class-${personParticipationId(1).value}')),
        matching: find.byType(TextField),
      ),
      'Expert',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final answer = guard.confirmLeave();
    await tester.pumpAndSettle();
    expect(find.text('Leave with unsaved changes?'), findsOneWidget);
    expect(
      find.textContaining('You have unsaved changes to 1 participant.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    expect(await answer, isFalse);
  });
}
