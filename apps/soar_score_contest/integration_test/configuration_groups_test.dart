import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the configuration shows scoring access and the lock, and '
      'sends the director to the Workspace to change them', (tester) async {
    await openMainPage(tester);
    await openContest(tester, 'Club Thermal Fun Fly');
    await openConfiguration(tester);

    // Both groups show their current value and the revision they live in.
    for (final title in ['Scoring access', 'Administration lock']) {
      expect(find.text(title, skipOffstage: false), findsWidgets);
    }
    expect(
      find.byKey(const ValueKey('state-scoringAccess'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('state-adminLock'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.textContaining('Config rev.', skipOffstage: false),
      findsWidgets,
    );

    // The controls themselves are on the Workspace.
    await tapVisible(tester, find.text('Change in Workspace').first);
    await pumpUntilFound(tester, find.text('Setup checklist'));
  });
}
