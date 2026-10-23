import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/before_unload_probe.dart';
import 'support/interact.dart';
import 'support/launch_app.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

/// Web mode only: the browser tab warns on close while a landing is being
/// edited and stays quiet otherwise. The Windows window hook has no
/// observable browser event; its Dart side is covered by widget tests.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('closing the tab is blocked only with unsaved edits', (
    tester,
  ) async {
    if (closeWouldBeBlocked() == null) {
      return; // Native build: no beforeunload event.
    }
    await openMainPage(tester);
    expect(closeWouldBeBlocked(), isFalse);

    await tapRail(tester, 'Landings');
    await pumpUntilFound(tester, _key('new-landing'));
    await tapVisible(tester, _key('new-landing'));
    await pumpUntilFound(tester, _key('landing-name'));
    // An untouched editor has nothing to lose.
    expect(closeWouldBeBlocked(), isFalse);

    await enterIn(tester, _key('landing-name'), 'E2E Unsaved Table');
    expect(closeWouldBeBlocked(), isTrue);

    // Leaving the editor discards the edits, so the warning goes away.
    await tapVisible(tester, find.text('Cancel'));
    await pumpUntilFound(tester, find.text('Discard changes?'));
    await tapVisible(tester, find.text('Discard'));
    await pumpUntilFound(tester, _key('new-landing'));
    expect(closeWouldBeBlocked(), isFalse);
  });
}
