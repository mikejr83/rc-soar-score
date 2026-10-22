import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/exchange_files.dart';
import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';

const _sent = 'E2E Sent Contest';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a sent contest is opened for inspection and not synced '
      '(#214, native)', (tester) async {
    fakeExchangeFiles(chosen: await contestFromAnotherInstallation(_sent));

    await openMainPage(tester);
    await importForInspection(tester, _sent);

    // The imported contest is selected, labelled and explained.
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('inspection-label')),
    );
    expect(find.text('Imported copy, not synced'), findsOneWidget);
    expect(find.byKey(const ValueKey('inspection-notice')), findsOneWidget);

    // The demo contests are not labelled.
    await selectContest(tester, 'Front Range F5J Open');
    expect(find.byKey(const ValueKey('inspection-label')), findsNothing);

    // The imported contest opens like any other.
    await openContest(tester, _sent);
  }, skip: kIsWeb);
}
