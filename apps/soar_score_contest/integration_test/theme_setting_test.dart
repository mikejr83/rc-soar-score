import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_settings.dart';

ThemeMode _appThemeMode(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

Set<ThemeMode> _selected(WidgetTester tester) => tester
    .widget<SegmentedButton<ThemeMode>>(
      find.byKey(const ValueKey('theme-mode-control')),
    )
    .selected;

Future<void> _choose(WidgetTester tester, String label) => tapVisible(
  tester,
  find.descendant(
    of: find.byKey(const ValueKey('theme-mode-control')),
    matching: find.text(label),
  ),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the theme is chosen on the Settings page and kept', (
    tester,
  ) async {
    await openMainPage(tester);
    await openSettings(tester);

    // The choice lives in the client's UI store, which a demo reset does not
    // clear, so start by putting it to System.
    await _choose(tester, 'System');
    expect(_appThemeMode(tester), ThemeMode.system);

    await _choose(tester, 'Dark');
    expect(_appThemeMode(tester), ThemeMode.dark);

    // Leaving and coming back shows the saved choice.
    await tapRail(tester, 'Roles');
    await pumpUntilFound(tester, find.text('Pilot'));
    await openSettings(tester);
    expect(_selected(tester), {ThemeMode.dark});

    await _choose(tester, 'Light');
    expect(_appThemeMode(tester), ThemeMode.light);

    // Leave the app on its default for the next run.
    await _choose(tester, 'System');
    expect(_appThemeMode(tester), ThemeMode.system);
  });
}
