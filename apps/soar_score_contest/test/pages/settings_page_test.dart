import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/app.dart';
import 'package:soar_score_contest/pages/settings_page.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/services/collapsible_areas/collapsible_area.dart';
import 'package:soar_score_contest/services/collapsible_areas/collapsible_areas_controller.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:soar_score_contest/services/preferences/preferences_controller.dart';
import 'package:soar_score_contest/services/text_size/text_size.dart';
import 'package:soar_score_contest/services/text_size/text_size_controller.dart';
import 'package:soar_score_contest/services/reports/viewer/report_options_store.dart';
import 'package:soar_score_contest/services/theme/theme_controller.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import '../support/fake_bootstrap.dart';

ThemeMode _appThemeMode(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

Future<void> _pumpSettings(
  WidgetTester tester,
  LocalUiStore store, {
  ThemeController? controller,
  TextSizeController? textSize,
  CollapsibleAreasController? areas,
  PreferencesController? locale,
}) async {
  tester.view.physicalSize = const Size(900, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    SoarScoreContestApp(
      bootstrap: FakeBootstrap(store),
      routerInitialLocation: settingsPath,
      themeController: controller,
      textSizeController: textSize,
      collapsibleAreas: areas,
      preferences: locale,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  _textSizeTests();
  testWidgets('the preferred locale is the one the app shows', (tester) async {
    final locale = PreferencesController()..setLocale('en-US');
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

  testWidgets('the report options card shows and resets every report', (
    tester,
  ) async {
    final uiStore = BackendLocalUiStore(MemoryLocalUiBackend());
    final options = ReportOptionsStore(uiStore, 'local');
    await options.set('matrix', {'cmp': '1'});
    await options.set('standings', {'pct': '1'});
    await _pumpSettings(tester, uiStore);

    expect(
      find.text(AppLocalizationsEn().reportOptionsHeading),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('reset-report-options-button')),
    );
    await tester.pumpAndSettle();

    expect(await options.load(), isEmpty);
    expect(
      find.text(AppLocalizationsEn().reportOptionsResetDone),
      findsOneWidget,
    );
  });

  testWidgets('a failed report options reset save is reported', (
    tester,
  ) async {
    final store = _FailingStore();
    await _pumpSettings(tester, store);

    await tester.tap(
      find.byKey(const ValueKey('reset-report-options-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(AppLocalizationsEn().reportOptionsResetSaveFailed),
      findsOneWidget,
    );
  });
}

double _bodyFontPx(WidgetTester tester) =>
    MediaQuery.textScalerOf(tester.element(find.byType(SettingsPage)))
        .scale(10);

Set<TextSize> _selectedSize(WidgetTester tester) => tester
    .widget<SegmentedButton<TextSize>>(
      find.byKey(const ValueKey('text-size-control')),
    )
    .selected;

void _textSizeTests() {
  testWidgets('the text size control starts on Default', (tester) async {
    await _pumpSettings(tester, BackendLocalUiStore(MemoryLocalUiBackend()));

    expect(_selectedSize(tester), {TextSize.standard});
    expect(_bodyFontPx(tester), 10);
  });

  for (final (label, size) in [
    ('Large', TextSize.large),
    ('Extra large', TextSize.extraLarge),
  ]) {
    testWidgets('choosing $label scales the text across the app', (
      tester,
    ) async {
      await _pumpSettings(tester, BackendLocalUiStore(MemoryLocalUiBackend()));
      final before = tester.getSize(
        find.byKey(const ValueKey('text-size-preview')),
      );

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('text-size-control')),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();

      expect(_selectedSize(tester), {size});
      expect(_bodyFontPx(tester), size.factor * 10);
      expect(
        tester.getSize(find.byKey(const ValueKey('text-size-preview'))).height,
        greaterThan(before.height),
      );
    });
  }

  testWidgets('the device text scale still counts on top of the choice', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final controller = TextSizeController();
    addTearDown(controller.dispose);
    await controller.setSize(TextSize.large);
    await _pumpSettings(
      tester,
      BackendLocalUiStore(MemoryLocalUiBackend()),
      textSize: controller,
    );

    expect(_bodyFontPx(tester), closeTo(15, 1e-9));
  });

  testWidgets('a failed text size save is reported and the size applies', (
    tester,
  ) async {
    await _pumpSettings(tester, _FailingStore());

    await tester.tap(find.text('Large'));
    await tester.pumpAndSettle();

    expect(_bodyFontPx(tester), 12.5);
    expect(find.text(AppLocalizationsEn().textSizeSaveFailed), findsOneWidget);
  });

  testWidgets('the text size is remembered by a fresh app on the same store', (
    tester,
  ) async {
    final store = BackendLocalUiStore(MemoryLocalUiBackend());
    await _pumpSettings(tester, store);
    await tester.tap(find.text('Extra large'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await _pumpSettings(tester, store);

    expect(_selectedSize(tester), {TextSize.extraLarge});
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
