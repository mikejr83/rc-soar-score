import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/participant_extras.dart';
import 'support/participant_form.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('deleting a participant asks first and removes the person', (
    tester,
  ) async {
    await openMainPage(tester);
    await openParticipantsManager(tester);
    await addParticipant(
      tester,
      first: 'E2E',
      last: 'Deleteme',
      email: 'e2e.deleteme@e2e.example',
    );
    await selectParticipant(tester, 'E2E Deleteme');

    // Cancel keeps the person.
    await tapVisible(tester, find.byTooltip('Delete E2E Deleteme'));
    await pumpUntilFound(tester, find.text('Delete participant?'));
    await tapVisible(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Delete participant?'), findsNothing);
    expect(participantRow('E2E Deleteme'), findsOneWidget);

    // Confirming removes the person from the list.
    await tapVisible(tester, find.byTooltip('Delete E2E Deleteme'));
    await pumpUntilFound(tester, find.text('Delete participant?'));
    await tapVisible(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Delete'),
      ),
    );
    await pumpUntilFound(tester, find.text('No participants match.'));
    expect(participantRow('E2E Deleteme'), findsNothing);
  });
}
