import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/participant_extras.dart';
import 'support/participant_form.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('leaving the participant editor with changes asks first', (
    tester,
  ) async {
    await openMainPage(tester);
    await openParticipantsManager(tester);
    await fillNewParticipant(
      tester,
      first: 'E2E',
      last: 'Discarded',
      email: 'e2e.discarded@e2e.example',
    );

    // Keep editing leaves the editor and its values as they were.
    await tapVisible(tester, find.byKey(const ValueKey('cancel-participant')));
    await pumpUntilFound(tester, find.text('Discard changes?'));
    await tapVisible(tester, find.text('Keep editing'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Discard changes?'), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('last-name')))
          .controller!
          .text,
      'Discarded',
    );

    // Discard returns to the manager without creating the person.
    await tapVisible(tester, find.byKey(const ValueKey('cancel-participant')));
    await pumpUntilFound(tester, find.text('Discard changes?'));
    await tapVisible(tester, find.text('Discard'));
    await pumpUntilFound(tester, participantSearch);
    await searchParticipants(tester, 'Discarded');
    await pumpUntilFound(tester, find.text('No participants match.'));
  });
}
