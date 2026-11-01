import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';
import 'support/open_settings.dart';

/// A ready demo contest: a drawn matrix, nothing scored yet.
const _contest = 'Front Range F5J Open';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The report options are a local setting that must start from a clean
  // install, like the theme and text size settings, so this test is a
  // standalone file rather than a step of the lifecycle journey.
  testWidgets('report options are remembered and reset from Settings', (
    tester,
  ) async {
    await openMainPage(tester);
    await openContest(tester, _contest);
    await tapRail(tester, 'Reports');
    await pumpUntilFound(tester, find.text('Reports are built from'));
    await tapVisible(tester, find.byKey(const ValueKey('report-open-matrix')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('viewer-title')));

    final compact = find.widgetWithText(SwitchListTile, 'Compact mode');
    // Start from a known value, whatever an earlier run left stored.
    if (tester.widget<SwitchListTile>(compact).value) {
      await tapVisible(tester, compact);
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(tester.widget<SwitchListTile>(compact).value, isFalse);

    // Change the option; it is written to the account's stored options.
    await tapVisible(tester, compact);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.widget<SwitchListTile>(compact).value, isTrue);

    // The reset on the Settings page clears every report's options.
    await tapVisible(tester, find.byKey(const ValueKey('viewer-back')));
    await pumpUntilFound(tester, find.text('Reports are built from'));
    await openSettings(tester);
    await tester.ensureVisible(
      find.byKey(const ValueKey('reset-report-options-button')),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('reset-report-options-button')),
    );
    await pumpUntilFound(
      tester,
      find.text('Report options are back to their defaults.'),
    );

    // Reopening the report shows the default again.
    await tapRail(tester, 'Reports');
    await pumpUntilFound(tester, find.text('Reports are built from'));
    await tapVisible(tester, find.byKey(const ValueKey('report-open-matrix')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('viewer-title')));
    expect(tester.widget<SwitchListTile>(compact).value, isFalse);
  });
}
