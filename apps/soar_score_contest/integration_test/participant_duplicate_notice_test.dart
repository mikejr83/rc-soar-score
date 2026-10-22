import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/participant_extras.dart';
import 'support/participant_form.dart';

const _email = 'e2e.duplicate@e2e.example';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a repeated email cannot create a second participant', (
    tester,
  ) async {
    await openMainPage(tester);
    await openParticipantsManager(tester);
    await addParticipant(tester, first: 'E2E', last: 'Original', email: _email);

    // Saving a second person with the same email stops at the decision.
    await fillNewParticipant(tester, first: 'E2E', last: 'Twin', email: _email);
    await tapVisible(tester, find.byKey(const ValueKey('save-participant')));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('duplicate-notice')),
    );
    expect(find.text('Someone with this email already exists'), findsOneWidget);
    expect(find.byKey(const ValueKey('create-separate')), findsNothing);

    // Use existing opens the editor of the person who already has the email.
    await tapVisible(tester, find.byKey(const ValueKey('use-existing')));
    final lastName = find.byKey(const ValueKey('last-name'));
    await pumpUntilFound(tester, lastName);
    String textOf(Finder field) =>
        tester.widget<TextField>(field).controller!.text;
    // The loaded profile fills the fields a moment after the editor opens.
    await pumpUntilFound(
      tester,
      find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.key == const ValueKey('last-name') &&
            w.controller!.text == 'Original',
        description: 'last name field with Original',
      ),
    );
    expect(textOf(find.byKey(const ValueKey('email'))), _email);
    // Nothing changed, so there is no bar to cancel from; leave by the rail.
    await tapRail(tester, 'Participants');
    await pumpUntilFound(tester, participantSearch);
    await searchParticipants(tester, 'E2E Twin');
    await pumpUntilFound(tester, find.text('No participants match.'));

    // Change the email goes back to the form; a different email saves.
    await fillNewParticipant(tester, first: 'E2E', last: 'Twin', email: _email);
    await tapVisible(tester, find.byKey(const ValueKey('save-participant')));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('duplicate-notice')),
    );
    await tapVisible(tester, find.byKey(const ValueKey('change-email')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('email')));
    await enterIn(
      tester,
      find.byKey(const ValueKey('email')),
      'e2e.twin@e2e.example',
    );
    await saveParticipant(tester);
    await searchParticipants(tester, 'E2E Twin');
    await pumpUntilFound(tester, participantRow('E2E Twin'));
    await searchParticipants(tester, 'E2E Original');
    await pumpUntilFound(tester, participantRow('E2E Original'));
  });
}
