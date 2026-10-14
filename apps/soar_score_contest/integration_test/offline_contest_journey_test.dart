import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // One test per file: `launchApp` starts the real app, which holds the demo
  // database and the embedded server's port for the life of the process. A
  // second `main()` in the same process finds them still in use.
  testWidgets('offline journey: main page, contest list, open a contest', (
    tester,
  ) async {
    await openMainPage(tester);
    await openContest(tester, 'Autumn F5J Classic');

    // Contest scope shows the contest's own destinations.
    expect(find.text('Matrix'), findsWidgets);
    await pumpUntilFound(tester, find.text('Workspace'));
  });
}
