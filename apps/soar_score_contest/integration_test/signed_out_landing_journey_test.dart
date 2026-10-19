import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/launch_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signed-out landing recovers and continues offline', (
    tester,
  ) async {
    await launchApp(tester, initialPump: Duration.zero);

    await pumpUntilFound(tester, find.text('Checking sign-in…'));
    await pumpUntilFound(tester, find.text('Sign-in unavailable'));
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);

    await tester.tap(find.text('Retry'));
    await pumpUntilFound(tester, find.text('Sign in'));
    expect(find.text('Sign-in unavailable'), findsNothing);

    if (!kIsWeb) {
      await tester.tap(find.text('Continue offline'));
      await pumpUntilFound(tester, find.text('Contests'));
    }
  });
}
