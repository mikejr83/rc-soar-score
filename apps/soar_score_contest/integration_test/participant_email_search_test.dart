import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/participant_extras.dart';
import 'support/participant_form.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the participants search finds a person by email', (
    tester,
  ) async {
    await openMainPage(tester);
    await openParticipantsManager(tester);
    await addParticipant(
      tester,
      first: 'E2E',
      last: 'Mailbox',
      email: 'quokka.finder@e2e.example',
    );

    // The email alone, with no part of the name, finds the row.
    await searchParticipants(tester, 'quokka.finder@e2e.example');
    await pumpUntilFound(tester, participantRow('E2E Mailbox'));

    // A part of the email works too, and an unknown email finds nobody.
    await searchParticipants(tester, 'quokka.finder');
    await pumpUntilFound(tester, participantRow('E2E Mailbox'));
    await searchParticipants(tester, 'nobody.here@e2e.example');
    await pumpUntilFound(tester, find.text('No participants match.'));
    expect(participantRow('E2E Mailbox'), findsNothing);
  });
}
