import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/app.dart';
import 'package:soar_score_contest/pages/settings_page.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/services/collapsible_areas/collapsible_area.dart';
import 'package:soar_score_contest/services/collapsible_areas/collapsible_areas_controller.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:soar_score_contest/services/locale/locale_controller.dart';
import 'package:soar_score_contest/services/theme/theme_controller.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import '../support/fake_bootstrap.dart';

ThemeMode _appThemeMode(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

Future<void> _pumpSettings(
  WidgetTester tester,
  LocalUiStore store, {
  ThemeController? controller,
  CollapsibleAreasController? areas,
  LocaleController? locale,
}) async {
  await tester.pumpWidget(
    SoarScoreContestApp(
      bootstrap: FakeBootstrap(store),
      routerInitialLocation: settingsPath,
      themeController: controller,
      collapsibleAreas: areas,
      localeController: locale,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the preferred locale is the one the app shows', (tester) async {
    final locale = LocaleController()..setPreferred('en-US');
    await _pumpSettings(
      tester,
      BackendLocalUiStore(MemoryLocalUiBackend()),
      locale: locale,
    );

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('en', 'US'),
    );
    expect(find.text(AppLocalizationsEn().appearanceHeading), findsOneWidget);
  });

  testWidgets('without a preference the device decides', (tester) async {
    await _pumpSettings(tester, BackendLocalUiStore(MemoryLocalUiBackend()));

    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).locale, isNull);
  });

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

  testWidgets('a failed save is reported and the theme still applies', (
    tester,
  ) async {
    await _pumpSettings(tester, _FailingStore());

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(_appThemeMode(tester), ThemeMode.dark);
    expect(find.text(AppLocalizationsEn().themeSaveFailed), findsOneWidget);
  });

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

  testWidgets('reset panels restores every hidden area to its default', (
    tester,
  ) async {
    final store = BackendLocalUiStore(MemoryLocalUiBackend());
    final areas = CollapsibleAreasController(store: store);
    addTearDown(areas.dispose);
    await areas.setOpen(matrixSummaryArea, false);
    await _pumpSettings(tester, store, areas: areas);
    expect(areas.isOpen(matrixSummaryArea), isFalse);

    await tester.tap(find.byKey(const ValueKey('reset-areas-button')));
    await tester.pumpAndSettle();

    expect(areas.isOpen(matrixSummaryArea), isTrue);
    expect(find.text(AppLocalizationsEn().panelsResetDone), findsOneWidget);
    final fresh = CollapsibleAreasController(store: store);
    addTearDown(fresh.dispose);
    await fresh.load();
    expect(fresh.isOpen(matrixSummaryArea), isTrue);
  });

  testWidgets('a failed reset save is reported', (tester) async {
    final store = _FailingStore();
    final areas = CollapsibleAreasController(store: store);
    addTearDown(areas.dispose);
    await _pumpSettings(tester, store, areas: areas);

    await tester.tap(find.byKey(const ValueKey('reset-areas-button')));
    await tester.pumpAndSettle();

    expect(
      find.text(AppLocalizationsEn().panelsResetSaveFailed),
      findsOneWidget,
    );
  });
}

/// A store whose writes fail, as the contract allows.
class _FailingStore extends BackendLocalUiStore {
  _FailingStore() : super(MemoryLocalUiBackend());

  @override
  Future<bool> set<T>(String accountId, LocalUiKey<T> key, T value) async =>
      false;

  @override
  Future<bool> remove<T>(String accountId, LocalUiKey<T> key) async => false;
}
