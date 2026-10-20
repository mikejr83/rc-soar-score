import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/app.dart';
import 'package:soar_score_contest/preferences_controller_provider.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/services/preferences/director_time.dart';
import 'package:soar_score_contest/services/preferences/preferences_controller.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import '../support/fake_bootstrap.dart';

Future<void> _pumpSettings(
  WidgetTester tester,
  PreferencesController preferences,
) async {
  tester.view.physicalSize = const Size(900, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    SoarScoreContestApp(
      bootstrap: FakeBootstrap(BackendLocalUiStore(MemoryLocalUiBackend())),
      routerInitialLocation: settingsPath,
      preferences: preferences,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the time zone follows the device until one is chosen', (
    tester,
  ) async {
    final preferences = PreferencesController();
    await _pumpSettings(tester, preferences);

    expect(find.text('Following this device.'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey('time-zone-device-button')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('choosing a zone applies it and the device button clears it', (
    tester,
  ) async {
    final preferences = PreferencesController();
    await _pumpSettings(tester, preferences);

    await tester.enterText(find.byType(TextField).first, 'rome');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Rome').last);
    await tester.pumpAndSettle();

    expect(preferences.timeZone, 'Europe/Rome');
    expect(find.text('Following this device.'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('time-zone-device-button')));
    await tester.pumpAndSettle();

    expect(preferences.timeZone, isNull);
    expect(find.text('Following this device.'), findsOneWidget);
  });

  testWidgets('a failed save is reported and the zone still applies', (
    tester,
  ) async {
    final preferences = PreferencesController(
      savePreferences: (_) async => throw StateError('signed out'),
    );
    await _pumpSettings(tester, preferences);

    await tester.enterText(find.byType(TextField).first, 'rome');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Rome').last);
    await tester.pumpAndSettle();

    expect(preferences.timeZone, 'Europe/Rome');
    expect(find.textContaining('could not be saved'), findsOneWidget);
  });

  testWidgets('the language choice offers the device and English', (
    tester,
  ) async {
    final preferences = PreferencesController();
    await _pumpSettings(tester, preferences);

    await tester.tap(find.byKey(const ValueKey('locale-null')));
    await tester.pumpAndSettle();

    expect(find.text("Use this device's language"), findsWidgets);
    expect(find.text('English (United States)'), findsWidgets);

    await tester.tap(find.text('English (United States)').last);
    await tester.pumpAndSettle();

    expect(preferences.localeTag, 'en-US');
  });

  testWidgets('director times change with the zone, without a restart', (
    tester,
  ) async {
    final preferences = PreferencesController();
    final utc = DateTime.utc(2026, 10, 8, 12, 31);
    await tester.pumpWidget(
      PreferencesControllerInherited(
        controller: preferences,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) => Text(DirectorTime.of(context)(utc)),
          ),
        ),
      ),
    );

    await preferences.setTimeZone('Europe/Rome');
    await tester.pump();
    expect(find.text('10/8/2026 14:31 CEST'), findsOneWidget);

    await preferences.setTimeZone('Asia/Tokyo');
    await tester.pump();
    expect(find.text('10/8/2026 21:31 JST'), findsOneWidget);
  });
}
