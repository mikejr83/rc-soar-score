import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/app.dart';
import 'package:soar_score_contest/pages/settings_page.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/services/theme/theme_controller.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import '../support/fake_bootstrap.dart';

ThemeMode _appThemeMode(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

Future<void> _pumpSettings(
  WidgetTester tester,
  LocalUiStore store, {
  ThemeController? controller,
}) async {
  await tester.pumpWidget(
    SoarScoreContestApp(
      bootstrap: FakeBootstrap(store),
      routerInitialLocation: settingsPath,
      themeController: controller,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the theme control starts on System', (tester) async {
    await _pumpSettings(tester, BackendLocalUiStore(MemoryLocalUiBackend()));

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(_appThemeMode(tester), ThemeMode.system);
    final control = tester.widget<SegmentedButton<ThemeMode>>(
      find.byKey(const ValueKey('theme-mode-control')),
    );
    expect(control.selected, {ThemeMode.system});
  });

  for (final (label, mode) in [
    ('Light', ThemeMode.light),
    ('Dark', ThemeMode.dark),
    ('System', ThemeMode.system),
  ]) {
    testWidgets('choosing $label applies it to the app', (tester) async {
      await _pumpSettings(tester, BackendLocalUiStore(MemoryLocalUiBackend()));
      // Start from another mode so System is a real change.
      if (mode == ThemeMode.system) {
        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(_appThemeMode(tester), mode);
    });
  }

  testWidgets('the choice is remembered by a fresh app on the same store', (
    tester,
  ) async {
    final store = BackendLocalUiStore(MemoryLocalUiBackend());
    await _pumpSettings(tester, store);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await _pumpSettings(tester, store);

    expect(_appThemeMode(tester), ThemeMode.dark);
  });
}
