import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/participant_form.dart';

/// A new person: first name, last name, email, club, city and state.
typedef _Person = (String, String, String, String, String, String);

const List<_Person> _people = [
  (
    'Zoe',
    'Whitfield',
    'zoe.whitfield@e2e.example',
    'E2E Soaring',
    'Golden',
    'CO',
  ),
  ('Milo', 'Okafor', 'milo.okafor@e2e.example', 'E2E Soaring', 'Boulder', 'CO'),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('new participants are added in the participants manager', (
    tester,
  ) async {
    await openMainPage(tester);
    await tapRail(tester, 'Participants');
    await pumpUntilFound(tester, participantSearch);

    for (final (first, last, email, club, city, state) in _people) {
      await tapVisible(tester, find.byKey(const ValueKey('add-participant')));
      await pumpUntilFound(tester, find.byKey(const ValueKey('first-name')));

      await enterIn(tester, find.byKey(const ValueKey('first-name')), first);
      await enterIn(tester, find.byKey(const ValueKey('last-name')), last);
      await enterIn(tester, find.byKey(const ValueKey('email')), email);
      await enterIn(tester, editorField('Club'), club);
      await enterIn(tester, editorField('City'), city);
      await enterIn(tester, editorField('State/province'), state);
      await saveParticipant(tester);
    }

    // Both are in the list and show their details.
    for (final (first, last, email, club, _, _) in _people) {
      await searchParticipants(tester, last);
      final row = participantRow('$first $last');
      await pumpUntilFound(tester, row);
      await tapVisible(tester, row);
      await pumpUntilFound(tester, find.text(email));
      expect(find.text(club), findsWidgets);
    }
  });
}
