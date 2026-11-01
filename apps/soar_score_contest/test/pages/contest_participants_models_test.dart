import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/participants_page_support.dart';

const _options = {
  'classes_enabled': true,
  'roles_enabled': true,
  'models_enabled': true,
};

ContestModelLink _link(
  int person,
  String name, {
  int revision = 0,
}) => ContestModelLink(
  id: Id.parse(
    '019c0000-0000-7000-8000-0000000a00${person.toString().padLeft(2, '0')}',
  ),
  contestId: ParticipantsServer().contest.id,
  contestParticipationId: personParticipationId(person),
  modelName: name,
  revision: revision,
);

Finder _editModels(int person) =>
    find.byKey(ValueKey('edit-models-${personParticipationId(person).value}'));

void main() {
  testWidgets('shows each pilot\'s models, and a notice, never an error, for '
      'a pilot without', (tester) async {
    final server = ParticipantsServer(options: _options)
      ..modelLinks.add(_link(1, 'Supra'));
    await pumpParticipantsPage(tester, server);

    expect(find.text('Supra'), findsOneWidget);
    // Pilots 2 to 4 have none; the two non-fliers show nothing.
    expect(find.text('No models entered'), findsNWidgets(3));
    expect(find.textContaining('Needs'), findsNothing);
    expect(_editModels(2), findsOneWidget);
    expect(_editModels(5), findsNothing);
  });

  testWidgets('adds a model to a pilot and shows it when the window closes', (
    tester,
  ) async {
    final server = ParticipantsServer(options: _options);
    await pumpParticipantsPage(tester, server);

    await tester.tap(_editModels(2));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('model-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('model-name')),
      'Estrella',
    );
    await tester.tap(find.byKey(const ValueKey('model-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('models-done')));
    await tester.pumpAndSettle();

    expect(server.modelLinks.single.modelName, 'Estrella');
    expect(
      server.modelLinks.single.contestParticipationId,
      personParticipationId(2),
    );
    // The typed model is kept on the person's profile for later contests.
    expect(server.profileModels.single.name, 'Estrella');
    expect(
      server.modelLinks.single.modelCatalogId,
      server.profileModels.single.id,
    );
    expect(find.text('Estrella'), findsOneWidget);
    expect(find.text('No models entered'), findsNWidgets(3));
  });

  testWidgets('a model is removed from a pilot', (tester) async {
    final server = ParticipantsServer(options: _options)
      ..modelLinks.add(_link(1, 'Supra'));
    await pumpParticipantsPage(tester, server);

    await tester.tap(_editModels(1));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('remove-model-${server.modelLinks.single.id.value}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('models-done')));
    await tester.pumpAndSettle();

    expect(server.modelLinks, isEmpty);
    expect(find.text('Supra'), findsNothing);
    expect(find.text('No models entered'), findsNWidgets(4));
  });

  testWidgets('a stale model shows the refresh message, then the fresh list '
      'when the window closes', (tester) async {
    final server = ParticipantsServer(options: _options)
      ..modelLinks.add(_link(1, 'Supra'));
    await pumpParticipantsPage(tester, server);

    await tester.tap(_editModels(1));
    await tester.pumpAndSettle();
    // Another director's session renames and then we try to edit.
    server.modelsStale = true;
    await tester.tap(
      find.byKey(ValueKey('remove-model-${server.modelLinks.single.id.value}')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('changed elsewhere'), findsOneWidget);
    server.modelsStale = false;
    server.modelLinks[0] = _link(1, 'Supra 2', revision: 1);
    await tester.tap(find.byKey(const ValueKey('models-done')));
    await tester.pumpAndSettle();

    expect(find.text('Supra 2'), findsOneWidget);
  });

  testWidgets('the Models column is absent when the option is off', (
    tester,
  ) async {
    await pumpParticipantsPage(tester, ParticipantsServer());

    expect(find.text('No models entered'), findsNothing);
    expect(find.text('Models'), findsNothing);
  });
}
