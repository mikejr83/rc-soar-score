import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:soar_score_contest/pages/home_page.dart';
import 'package:soar_score_contest/pages/landing_page.dart';

import 'support/launch_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // One test per file run: `launchApp` starts the real app, which holds the
  // demo database and the embedded server's port for the life of the process.
  // A second `main()` in the same process finds them still in use.
  testWidgets('offline journey: landing, contest list, open a contest', (
    tester,
  ) async {
    await launchApp(tester);

    await pumpUntilFound(tester, find.byType(LandingPage));
    await tester.tap(find.text('Continue offline'));

    await pumpUntilFound(tester, find.byType(HomePage));
    await pumpUntilFound(tester, find.text('Autumn F5J Classic'));

    await tester.tap(find.text('Autumn F5J Classic'));

    // Contest scope shows the contest's own destinations.
    await pumpUntilFound(tester, find.text('Workspace'));
    expect(find.text('Matrix'), findsWidgets);
  });
}
