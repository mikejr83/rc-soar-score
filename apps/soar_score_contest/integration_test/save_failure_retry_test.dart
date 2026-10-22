import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/participant_extras.dart';
import 'support/participant_form.dart';

/// Web mode only. The failure comes from `POST /__e2e/fail-next-write` on the
/// test server (`apps/soar_score_server/tool/e2e_server.dart`), which the
/// Windows build does not use: its embedded server is the real one and gets
/// no fault hook. The Retry and Dismiss paths are covered on every target by
/// the participant and landing editor widget tests.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const apiBase = String.fromEnvironment('SOAR_SCORE_API_BASE_URL');

  testWidgets('a failed save keeps the values and Retry saves once', (
    tester,
  ) async {
    if (apiBase.isEmpty) {
      return; // No test server to inject the failure: native build.
    }
    await openMainPage(tester);
    await openParticipantsManager(tester);
    await fillNewParticipant(
      tester,
      first: 'E2E',
      last: 'Retried',
      email: 'e2e.retried@e2e.example',
    );

    // The next write fails once.
    final armed = await http.post(Uri.parse('$apiBase/__e2e/fail-next-write'));
    expect(armed.statusCode, 200);

    await tapVisible(tester, find.byKey(const ValueKey('save-participant')));
    final failure = find.byKey(const ValueKey('save-error'));
    await pumpUntilFound(tester, failure);
    expect((failure.evaluate().single.widget as Text).data, contains('kept'));
    // Still on the editor with every value.
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('last-name')))
          .controller!
          .text,
      'Retried',
    );

    // Retry sends the same profile and returns to the manager.
    await tapVisible(tester, find.text('Retry'));
    await pumpUntilFound(tester, participantSearch);
    await searchParticipants(tester, 'Retried');
    await pumpUntilFound(tester, participantRow('E2E Retried'));
    expect(participantRow('E2E Retried'), findsOneWidget);
  });
}
