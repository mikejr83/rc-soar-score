import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/participants_page_support.dart';

Finder _field(String kind, int n) => find.descendant(
  of: find.byKey(ValueKey('$kind-${personParticipationId(n).value}')),
  matching: find.byType(TextField),
);

Finder _status(int n) =>
    find.byKey(ValueKey('status-${personParticipationId(n).value}'));

String _text(WidgetTester tester, Finder field) =>
    tester.widget<TextField>(field).controller!.text;

Future<void> _type(WidgetTester tester, Finder field, String text) async {
  await tester.enterText(field, text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

Finder _save() => find.byKey(const ValueKey('save-participants'));

bool _saveEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_save()).onPressed != null;

Future<void> _pickRole(WidgetTester tester, int person, String role) async {
  await tester.tap(
    find.byKey(ValueKey('role-${personParticipationId(person).value}')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(role).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an edit marks the row Unsaved and turns Save on', (
    tester,
  ) async {
    await pumpParticipantsPage(tester, ParticipantsServer());

    await _type(tester, _field('class', 1), 'sportsman');

    expect(
      find.descendant(of: _status(1), matching: find.text('Unsaved')),
      findsOneWidget,
    );
    expect(_saveEnabled(tester), isTrue);
    expect(find.text('Unsaved changes to 1 participant'), findsOneWidget);
    expect(find.byKey(const ValueKey('discard-participants')), findsOneWidget);
    // While edits wait for Save, Add steps down to the tonal button.
    final scheme = Theme.of(tester.element(_save())).colorScheme;
    final add = find.descendant(
      of: find.byKey(const ValueKey('add-participant-new')),
      matching: find.byType(Material),
    );
    expect(tester.widget<Material>(add.first).color, scheme.secondaryContainer);
  });

  testWidgets('Discard throws the edits away', (tester) async {
    await pumpParticipantsPage(tester, ParticipantsServer());
    await _type(tester, _field('class', 1), 'Expert');

    await tester.tap(find.byKey(const ValueKey('discard-participants')));
    await tester.pumpAndSettle();

    expect(find.text('Unsaved changes to 1 participant'), findsNothing);
    expect(find.text('No changes to save.'), findsOneWidget);
    expect(_text(tester, _field('class', 1)), 'Open');
  });

  testWidgets('Save sends a changed class with the revision it read', (
    tester,
  ) async {
    final server = ParticipantsServer();
    await pumpParticipantsPage(tester, server);
    await _type(tester, _field('class', 1), 'expert');

    await tester.tap(_save());
    await tester.pumpAndSettle();

    final update = server.updates.single;
    expect(update.id, personParticipationId(1));
    expect(update.body['base_revision'], 0);
    expect(update.body['classification'], 'Expert');
    expect(update.body['role_id'], isNull);
    expect(
      find.descendant(of: _status(1), matching: find.text('Saved')),
      findsOneWidget,
    );
    expect(find.text('1 participant saved.'), findsOneWidget);
    expect(find.text('No changes to save.'), findsOneWidget);
  });

  testWidgets('a new team is created and the pilot moves to it', (
    tester,
  ) async {
    final server = ParticipantsServer();
    await pumpParticipantsPage(tester, server);
    await _type(tester, _field('team', 1), 'lake wings');

    await tester.tap(_save());
    await tester.pumpAndSettle();

    expect(server.updates, isEmpty);
    expect(server.teamCreations.single['name'], 'Lake Wings');
    // Person 1 leaves the Gators and joins the new team.
    expect(server.membershipRemovals, hasLength(1));
    expect(
      server.membershipAdds.single['contest_participation_id'],
      personParticipationId(1).value,
    );
  });

  testWidgets('a matching team is joined without creating one', (tester) async {
    final server = ParticipantsServer();
    await pumpParticipantsPage(tester, server);
    await _type(tester, _field('team', 5), 'harbor hawks');

    await tester.tap(_save());
    await tester.pumpAndSettle();

    expect(server.teamCreations, isEmpty);
    expect(server.membershipRemovals, isEmpty);
    expect(server.membershipAdds, hasLength(1));
  });

  testWidgets('clearing a class turns Save off and says which row', (
    tester,
  ) async {
    await pumpParticipantsPage(tester, ParticipantsServer());

    await _type(tester, _field('class', 1), '');

    expect(_saveEnabled(tester), isFalse);
    expect(find.text('Fix 1 row before saving.'), findsOneWidget);
    expect(
      find.descendant(of: _status(1), matching: find.text('Needs class')),
      findsOneWidget,
    );
  });

  testWidgets('a team name over 40 characters needs fixing', (tester) async {
    await pumpParticipantsPage(tester, ParticipantsServer());

    await _type(
      tester,
      _field('team', 1),
      'Gainesville Area Thermal Soaring Society Team A',
    );

    expect(_saveEnabled(tester), isFalse);
    expect(
      find.textContaining('Team names can be up to 40 characters'),
      findsOneWidget,
    );
  });

  testWidgets('a failed row keeps its values and the others save', (
    tester,
  ) async {
    final server = ParticipantsServer()
      ..updateFailures[personParticipationId(2)] = (500, 'internal_error');
    await pumpParticipantsPage(tester, server);
    await _type(tester, _field('class', 1), 'Expert');
    await _type(tester, _field('class', 2), 'Open');

    await tester.tap(_save());
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: _status(1), matching: find.text('Saved')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _status(2), matching: find.text('Not saved')),
      findsOneWidget,
    );
    expect(
      find.text('1 saved. 1 not saved. Their typed values are kept.'),
      findsOneWidget,
    );
    expect(_text(tester, _field('class', 2)), 'Open');

    // Undo row changes drops just that row's edits.
    await tester.tap(find.text('Undo row changes'));
    await tester.pumpAndSettle();
    expect(_text(tester, _field('class', 2)), 'Sportsman');
  });

  testWidgets('a participant changed elsewhere asks for a refresh', (
    tester,
  ) async {
    final server = ParticipantsServer();
    await pumpParticipantsPage(tester, server);
    await _type(tester, _field('class', 1), 'Sportsman');
    server.changeElsewhere(1);

    await tester.tap(_save());
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This participant was changed elsewhere. Refresh to see the latest.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Someone changed this participant. Refresh to continue.'),
      findsOneWidget,
    );
    expect(_saveEnabled(tester), isFalse);

    await tester.tap(find.text('Refresh').first);
    await tester.pumpAndSettle();

    expect(find.text('No changes to save.'), findsOneWidget);
    expect(_text(tester, _field('class', 1)), 'Expert');
  });

  testWidgets('making a pilot non-flying asks first; cancelling puts the '
      'role back', (tester) async {
    await pumpParticipantsPage(tester, ParticipantsServer());

    await _pickRole(tester, 2, 'Helper');

    expect(find.text('Change Bo Ray to Helper?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Unsaved changes to 1 participant'), findsNothing);
    expect(find.text('No changes to save.'), findsOneWidget);
  });

  testWidgets('a confirmed role change clears the class and saves', (
    tester,
  ) async {
    final server = ParticipantsServer();
    await pumpParticipantsPage(tester, server);

    await _pickRole(tester, 2, 'Helper');
    await tester.tap(find.byKey(const ValueKey('confirm-role-change')));
    await tester.pumpAndSettle();

    expect(_saveEnabled(tester), isTrue);
    await tester.tap(_save());
    await tester.pumpAndSettle();

    final body = server.updates.single.body;
    expect(body['role_id'], SystemRoles.helperId.value);
    expect(body['classification'], isNull);
  });

  testWidgets('a pilot with flights cannot be made non-flying', (tester) async {
    await pumpParticipantsPage(
      tester,
      ParticipantsServer(
        state: LifecycleState.running,
        drawn: true,
        withScores: true,
      ),
    );

    await tester.tap(
      find.byKey(ValueKey('role-${personParticipationId(1).value}')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Helper (not available: has flights)'), findsOneWidget);
  });

  testWidgets('a saved change in a running contest says results are '
      'recalculated', (tester) async {
    final server = ParticipantsServer(
      state: LifecycleState.running,
      drawn: true,
    );
    await pumpParticipantsPage(tester, server);
    await _type(tester, _field('class', 2), 'Open');

    await tester.tap(_save());
    await tester.pumpAndSettle();

    expect(find.text('Results are recalculated'), findsOneWidget);
    expect(find.textContaining('Bo Ray’s class changed'), findsOneWidget);
  });

  testWidgets('a failed recalculation after a team change is reported', (
    tester,
  ) async {
    final server =
        ParticipantsServer(state: LifecycleState.running, drawn: true)
          ..warning =
              'Recalculation failed after a team change; the results are stale';
    await pumpParticipantsPage(tester, server);
    await _type(tester, _field('team', 1), 'harbor hawks');

    await tester.tap(_save());
    await tester.pumpAndSettle();

    expect(find.text('Results are recalculated'), findsOneWidget);
    expect(find.textContaining('the results are stale'), findsOneWidget);
  });

  testWidgets('a notice from leaving the old team survives a failed join', (
    tester,
  ) async {
    final server =
        ParticipantsServer(state: LifecycleState.running, drawn: true)
          ..warning = 'Recalculation failed after a team change; stale'
          ..membershipAddFailure = 500;
    await pumpParticipantsPage(tester, server);
    await _type(tester, _field('team', 1), 'harbor hawks');

    await tester.tap(_save());
    await tester.pumpAndSettle();

    // The old membership is gone, so the results may be stale even though
    // the row did not save.
    expect(server.membershipRemovals, hasLength(1));
    expect(
      find.descendant(of: _status(1), matching: find.text('Not saved')),
      findsOneWidget,
    );
    expect(find.text('Results are recalculated'), findsOneWidget);
    expect(find.textContaining('team change; stale'), findsOneWidget);
  });

  testWidgets('editing a row never writes to the reusable profile', (
    tester,
  ) async {
    final server = ParticipantsServer();
    await pumpParticipantsPage(tester, server);
    await _type(tester, _field('class', 1), 'Expert');
    await _type(tester, _field('team', 2), 'lake wings');
    await _pickRole(tester, 3, 'Helper');
    await tester.tap(find.byKey(const ValueKey('confirm-role-change')));
    await tester.pumpAndSettle();

    await tester.tap(_save());
    await tester.pumpAndSettle();

    expect(server.writes, isNotEmpty);
    // Only participations, teams and memberships change; the profile
    // routes (`/participants`) are never written.
    expect(
      server.writes.where((w) => RegExp(r'/participants(/|$)').hasMatch(w)),
      isEmpty,
    );
  });

  testWidgets('a banner going away does not lose the typed search text', (
    tester,
  ) async {
    await pumpParticipantsPage(tester, ParticipantsServer());
    final search = find.descendant(
      of: find.byKey(const ValueKey('participant-search')),
      matching: find.byType(TextField),
    );
    await tester.enterText(search, 'park');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('banner-missing-class')), findsOneWidget);

    // Giving the pilot a class removes the missing-class banner.
    await _type(tester, _field('class', 4), 'Open');

    expect(find.byKey(const ValueKey('banner-missing-class')), findsNothing);
    expect(_text(tester, search), 'park');
    expect(find.text('Di Park'), findsOneWidget);
  });
}
