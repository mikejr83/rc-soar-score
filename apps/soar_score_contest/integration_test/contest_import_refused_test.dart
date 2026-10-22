import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/exchange_files.dart';
import 'support/interact.dart';
import 'support/launch_app.dart';

const _sent = 'E2E Sent Twice';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the same file is not imported twice (#214, native)', (
    tester,
  ) async {
    fakeExchangeFiles(chosen: await contestFromAnotherInstallation(_sent));

    await openMainPage(tester);
    await importForInspection(tester, _sent);

    await tapVisible(tester, find.byKey(const ValueKey('import-contest')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('import-dialog')));

    // The dialog names the copy that is already here and offers no way on.
    expect(
      find.textContaining('already in this database as "$_sent"'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('import-mode-inspection')), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('import-confirm')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(_sent), findsWidgets);
  }, skip: kIsWeb);
}
