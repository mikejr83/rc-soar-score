import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/participant_form.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('an existing participant is edited and the change is shown', (
    tester,
  ) async {
    await openMainPage(tester);
    await tapRail(tester, 'Participants');
    await pumpUntilFound(tester, participantSearch);

    // Avery Brooks is the first person of the demo roster.
    await searchParticipants(tester, 'Avery Brooks');
    final row = participantRow('Avery Brooks');
    await pumpUntilFound(tester, row);
    await tapVisible(tester, row);
    await pumpUntilFound(tester, find.text('Front Range Soaring'));

    await tapVisible(tester, find.byKey(const ValueKey('edit-participant')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('first-name')));
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('first-name')))
          .controller!
          .text,
      'Avery',
    );

    // The demo roster has no emails and the editor requires one.
    await enterIn(
      tester,
      find.byKey(const ValueKey('email')),
      'avery@example.com',
    );
    await enterIn(tester, editorField('Club'), 'E2E Soaring Club');
    await enterIn(tester, editorField('City'), 'Evergreen');
    await saveParticipant(tester);

    // The list shows the edited person, with the new values.
    await searchParticipants(tester, 'Avery Brooks');
    await tapVisible(tester, participantRow('Avery Brooks'));
    await pumpUntilFound(tester, find.text('E2E Soaring Club'));
    expect(find.text('Evergreen'), findsWidgets);
    expect(find.text('Front Range Soaring'), findsNothing);
  });
}
