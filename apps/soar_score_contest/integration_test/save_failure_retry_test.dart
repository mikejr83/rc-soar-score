import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';

/// The landings manager's list row of the table called [name].
Finder _landingRow(String name) =>
    find.descendant(of: find.byType(ListTile), matching: find.text(name));

Finder _key(String key) => find.byKey(ValueKey(key));

/// Web mode only. The failure comes from `POST /__e2e/fail-next-write` on the
/// test server (`apps/soar_score_server/tool/e2e_server.dart`), which the
/// Windows build does not use: its embedded server is the real one and gets
/// no fault hook. The Retry and Dismiss paths are covered on every target by
/// the landing editor widget tests.
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
    await tapRail(tester, 'Landings');
    await pumpUntilFound(tester, _key('new-landing'));
    await tapVisible(tester, _key('new-landing'));
    await pumpUntilFound(tester, _key('landing-name'));
    await enterIn(tester, _key('landing-name'), 'E2E Retried Table');
    await enterIn(tester, _key('entry-label-0'), 'Inside 2 m');
    await enterIn(tester, _key('entry-points-0'), '20');

    // The next write fails once.
    final armed = await http.post(Uri.parse('$apiBase/__e2e/fail-next-write'));
    expect(armed.statusCode, 200);

    await tapVisible(tester, _key('save-landing'));
    await pumpUntilFound(tester, _key('save-error'));
    expect(
      (_key('save-error').evaluate().single.widget as Text).data,
      contains('Everything you entered is kept'),
    );
    // Still on the editor with every value.
    expect(
      tester.widget<TextFormField>(_key('landing-name')).controller!.text,
      'E2E Retried Table',
    );

    // Retry sends the same table and returns to the list, once.
    await tapVisible(tester, find.text('Retry'));
    await pumpUntilFound(tester, _landingRow('E2E Retried Table'));
    expect(_landingRow('E2E Retried Table'), findsOneWidget);
  });
}
