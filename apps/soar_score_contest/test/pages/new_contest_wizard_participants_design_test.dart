import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/participants/participant_option.dart';
import 'package:soar_score_contest/widgets/participants/participants_table.dart';

import '../support/new_contest_test_support.dart';
import '../support/participants_step_support.dart';

Finder _inTable(Finder matching) =>
    find.descendant(of: find.byType(ParticipantsTable), matching: matching);

void main() {
  testWidgets('Add participant is the filled primary action', (tester) async {
    final store = await storeAtStep4();
    await pumpWizard(tester, respond: stepApi, store: store);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.key == const ValueKey('add-participant-new') &&
            widget is FilledButton,
      ),
      findsOneWidget,
    );
  });

  testWidgets('the email cell says Has email or None, never the address', (
    tester,
  ) async {
    final store = await storeAtStep4(
      participants: [row(0, classification: 'Open')],
    );
    await pumpWizard(tester, respond: stepApi, store: store);

    expect(_inTable(find.text('Has email')), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
  });

  testWidgets('the Models column says nothing can be recorded yet and never '
      'blocks continuing', (tester) async {
    final store = await storeAtStep4(
      options: const {ParticipantOption.classes, ParticipantOption.models},
      participants: [
        row(0, classification: 'Open'),
        row(1, classification: 'Open'),
      ],
    );
    await pumpWizard(tester, respond: stepApi, store: store);

    expect(_inTable(find.text('Models')), findsOneWidget);
    expect(find.text('Model *'), findsNothing);
    expect(
      _inTable(find.text('No models information entered.')),
      findsNWidgets(2),
    );
    expect(find.textContaining('fixing before you continue'), findsNothing);
  });

  testWidgets('the search field also filters the list', (tester) async {
    final store = await storeAtStep4(
      participants: [
        row(0, classification: 'Open', team: 'Flying Gators'),
        row(1, classification: 'Open', team: 'Lake Wings'),
      ],
    );
    await pumpWizard(tester, respond: stepApi, store: store);

    final field = find.descendant(
      of: find.byKey(const ValueKey('participant-search')),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, 'lake');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('participants-filter-note')),
      findsOneWidget,
    );
    expect(find.text('Showing 1 of 2 matching “lake”'), findsOneWidget);
    expect(_inTable(find.text('Gary Novak')), findsOneWidget);
    expect(_inTable(find.text('Mike Gardner')), findsNothing);

    await tester.enterText(field, 'zzz');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('participants-filter-empty')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(_inTable(find.text('Mike Gardner')), findsOneWidget);
    expect(_inTable(find.text('Gary Novak')), findsOneWidget);
  });

  testWidgets('the search field matches an email without showing it', (
    tester,
  ) async {
    final store = await storeAtStep4(
      participants: [
        row(0, classification: 'Open'),
        row(1, classification: 'Open'),
      ],
    );
    await pumpWizard(tester, respond: stepApi, store: store);

    final email = store.draft.participants[1].email!;
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('participant-search')),
        matching: find.byType(TextField),
      ),
      email,
    );
    await tester.pumpAndSettle();
    expect(_inTable(find.text('Gary Novak')), findsOneWidget);
    expect(_inTable(find.text('Mike Gardner')), findsNothing);
    expect(_inTable(find.textContaining('@')), findsNothing);
  });
}
