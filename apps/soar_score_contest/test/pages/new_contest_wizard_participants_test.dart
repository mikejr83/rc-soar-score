import 'dart:convert' as convert;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/participants/participant_option.dart';
import 'package:soar_score_contest/widgets/participants/participant_card.dart';
import 'package:soar_score_contest/widgets/participants/participants_table.dart';

import '../support/new_contest_test_support.dart';
import '../support/participant_test_support.dart';
import '../support/participants_step_support.dart';

Finder _class(int index) => find.descendant(
  of: find.byKey(ValueKey('class-${stepProfiles[index].id.value}')),
  matching: find.byType(TextField),
);

Finder _team(int index) => find.descendant(
  of: find.byKey(ValueKey('team-${stepProfiles[index].id.value}')),
  matching: find.byType(TextField),
);

/// The rows marked Ready (the status bar also says Ready).
Finder _ready() => find.descendant(
  of: find.byType(ParticipantsTable),
  matching: find.text('Ready'),
);

void main() {
  testWidgets('search adds people as Pilots and marks those already added', (
    tester,
  ) async {
    final store = await storeAtStep4();
    await pumpWizard(tester, respond: stepApi, store: store);

    expect(stepTitle(tester), 'Participants');
    expect(find.byKey(const ValueKey('participants-empty')), findsOneWidget);

    await searchAndPick(tester, 'gardner', 'Mike Gardner');
    expect(find.text('Mike Gardner added as Pilot.'), findsOneWidget);
    expect(store.draft.participants.single.name, 'Mike Gardner');
    expect(store.draft.participants.single.roleName, 'Pilot');
    expect(find.byType(ParticipantsTable), findsOneWidget);
    // One scoring pilot is not enough.
    expect(find.text('Add at least 2 scoring pilots'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('participant-search')),
        matching: find.byType(TextField),
      ),
      'ga',
    );
    await tester.pumpAndSettle();
    final already = tester.widget<ListTile>(
      find.byKey(ValueKey('search-result-${stepProfiles[0].id.value}')),
    );
    expect(already.enabled, isFalse);
    expect(find.text('Already in this contest'), findsOneWidget);
  });

  testWidgets('a missing class blocks Next and the summary jumps to it; the '
      'class is title-cased', (tester) async {
    final store = await storeAtStep4(
      participants: [
        row(0, classification: 'Open'),
        row(1),
      ],
    );
    await pumpWizard(tester, respond: stepApi, store: store);

    expect(
      find.text('1 participant needs fixing before you continue'),
      findsOneWidget,
    );
    expect(find.text('Needs class'), findsOneWidget);
    expect(find.text('Needs fixing (1)'), findsOneWidget);
    await next(tester);
    expect(stepTitle(tester), 'Participants');

    await tester.tap(find.text('Gary Novak: enter a class'));
    await tester.pump();
    expect(tester.widget<TextField>(_class(1)).focusNode!.hasFocus, isTrue);

    await tester.enterText(_class(1), 'sportsman');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(store.draft.participants[1].classification, 'Sportsman');
    expect(_ready(), findsNWidgets(2));

    // Two scoring pilots: a warning, but Next works.
    expect(find.text('Only 2 scoring pilots'), findsOneWidget);
    await next(tester);
    expect(stepTitle(tester), 'Scoring & publication');
  });

  testWidgets('a typed team matches an existing one ignoring case; a blank '
      'team is unassigned, not an error', (tester) async {
    final store = await storeAtStep4(
      participants: [
        row(0, classification: 'Open', team: 'Flying Gators'),
        row(1, classification: 'Open'),
      ],
    );
    await pumpWizard(tester, respond: stepApi, store: store);
    expect(_ready(), findsNWidgets(2));

    await tester.enterText(_team(1), 'flying gators');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(store.draft.participants[1].team, 'Flying Gators');

    await tester.enterText(_team(1), 'lake wings');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(store.draft.participants[1].team, 'Lake Wings');
  });

  testWidgets('bulk edit sets the class of the selected rows', (tester) async {
    final store = await storeAtStep4(
      participants: [
        row(0, classification: 'Open'),
        row(1),
        row(2),
      ],
    );
    await pumpWizard(tester, respond: stepApi, store: store);

    await tester.tap(find.bySemanticsLabel('Select Gary Novak'));
    await tester.tap(find.bySemanticsLabel('Select Sarah Albright'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bulk-class')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'Open'));
    await tester.pumpAndSettle();

    expect(store.draft.participants.map((p) => p.classification), [
      'Open',
      'Open',
      'Open',
    ]);
    expect(find.text('Class set to Open for 2 participants.'), findsOneWidget);
  });

  testWidgets('a non-flying role is not scored and needs no class', (
    tester,
  ) async {
    final store = await storeAtStep4(
      participants: [
        row(0, classification: 'Open'),
        row(1, classification: 'Open'),
        row(2),
      ],
    );
    await pumpWizard(tester, respond: stepApi, store: store);
    expect(find.text('3 scoring pilots'), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('role-${stepProfiles[2].id.value}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Helper').last);
    await tester.pumpAndSettle();

    expect(store.draft.participants[2].isPilot, isFalse);
    expect(find.text('2 scoring pilots'), findsOneWidget);
    expect(find.text('Non-flying'), findsOneWidget);
    expect(tester.widget<TextField>(_class(2)).enabled, isFalse);
  });

  testWidgets('Add participant opens the editor and selects the new person', (
    tester,
  ) async {
    final store = await storeAtStep4(options: const {ParticipantOption.teams});
    await pumpWizard(tester, respond: stepApi, store: store);

    await tester.tap(find.byKey(const ValueKey('add-participant-new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('first-name')), 'Jordan');
    await tester.enterText(find.byKey(const ValueKey('last-name')), 'Lee');
    await tester.enterText(
      find.byKey(const ValueKey('email')),
      'jordan.lee@example.com',
    );
    await tester.pump();
    expect(find.text('Add to contest'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('save-participant')));
    await tester.pumpAndSettle();

    expect(store.draft.participants.single.name, 'Jordan Lee');
    expect(find.text('1 selected'), findsNothing);
    expect(find.text('Jordan Lee is added as Pilot.'), findsOneWidget);
    // Roles are off, so one pilot count replaces the three chips.
    expect(find.text('1 pilots'), findsOneWidget);
    expect(find.textContaining('non-flying'), findsNothing);
  });

  testWidgets('Save and add another keeps every person in the draft', (
    tester,
  ) async {
    final store = await storeAtStep4(options: const {ParticipantOption.teams});
    var created = 0;
    await pumpWizard(
      tester,
      respond: (request) async {
        if (request.url.path.endsWith('/participants') &&
            request.method == 'POST') {
          final body = convert.jsonDecode(request.body) as Map<String, dynamic>;
          return json(
            profile(
              body['first_name'] as String,
              body['last_name'] as String,
              n: 40 + created++,
            ).toJson(),
          );
        }
        return stepApi(request);
      },
      store: store,
    );

    await tester.tap(find.byKey(const ValueKey('add-participant-new')));
    await tester.pumpAndSettle();
    Future<void> fill(String first, String last) async {
      await tester.enterText(find.byKey(const ValueKey('first-name')), first);
      await tester.enterText(find.byKey(const ValueKey('last-name')), last);
      await tester.enterText(
        find.byKey(const ValueKey('email')),
        '$first.$last@example.com'.toLowerCase(),
      );
      await tester.pump();
    }

    await fill('Jordan', 'Lee');
    await tester.tap(find.byKey(const ValueKey('save-add-another')));
    await tester.pumpAndSettle();
    // Let the "added" snackbar go; it covers the buttons.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await fill('Casey', 'Park');
    await tester.tap(find.byKey(const ValueKey('save-add-another')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await fill('Robin', 'Diaz');
    await tester.tap(find.byKey(const ValueKey('save-participant')));
    await tester.pumpAndSettle();

    expect(store.draft.participants.map((p) => p.name), [
      'Jordan Lee',
      'Casey Park',
      'Robin Diaz',
    ]);
  });

  testWidgets('cancelling after Save and add another keeps the saved ones', (
    tester,
  ) async {
    final store = await storeAtStep4(options: const {ParticipantOption.teams});
    await pumpWizard(tester, respond: stepApi, store: store);

    await tester.tap(find.byKey(const ValueKey('add-participant-new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('first-name')), 'Jordan');
    await tester.enterText(find.byKey(const ValueKey('last-name')), 'Lee');
    await tester.enterText(
      find.byKey(const ValueKey('email')),
      'jordan.lee@example.com',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('save-add-another')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();

    expect(store.draft.participants.map((p) => p.name), ['Jordan Lee']);
  });

  testWidgets('narrow windows stack the rows as cards', (tester) async {
    final store = await storeAtStep4(participants: [row(0), row(1)]);
    await pumpWizard(
      tester,
      respond: stepApi,
      store: store,
      size: const Size(800, 1180),
    );

    expect(find.byType(ParticipantsTable), findsNothing);
    expect(find.byType(ParticipantCard), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
