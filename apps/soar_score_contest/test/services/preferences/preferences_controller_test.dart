import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/preferences/preferences_controller.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  preferencesSavingTests();

  test('a supported tag becomes a locale with its region', () {
    expect(
      PreferencesController().localeFor('en-US'),
      const Locale('en', 'US'),
    );
  });

  test('no or an unsupported tag follows the device', () {
    expect(PreferencesController().localeFor(null), isNull);
    expect(PreferencesController().localeFor('xx-XX'), isNull);
  });

  test('load applies the account preference and notifies', () async {
    final controller = PreferencesController(
      loadPreferences: () async => AccountPreferences(preferredLocale: 'en-US'),
    );
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.load();

    expect(controller.locale, const Locale('en', 'US'));
    expect(notified, 1);
  });

  test('a failing load leaves the device locale', () async {
    final controller = PreferencesController(
      loadPreferences: () async => throw StateError('offline'),
    );

    await controller.load();

    expect(controller.locale, isNull);
  });
}

void preferencesSavingTests() {
  group('changing preferences', () {
    test('a zone applies at once and is saved with the locale', () async {
      AccountPreferences? saved;
      final controller = PreferencesController(
        savePreferences: (preferences) async => saved = preferences,
      );
      var notified = 0;
      controller.addListener(() => notified++);

      final ok = await controller.setTimeZone('Europe/Rome');

      expect(ok, isTrue);
      expect(controller.timeZone, 'Europe/Rome');
      expect(notified, 1);
      expect(saved?.preferredTimeZone, 'Europe/Rome');
      expect(saved?.preferredLocale, isNull);
    });

    test('a locale keeps the zone already chosen', () async {
      AccountPreferences? saved;
      final controller = PreferencesController(
        loadPreferences: () async =>
            AccountPreferences(preferredTimeZone: 'Asia/Tokyo'),
        savePreferences: (preferences) async => saved = preferences,
      );
      await controller.load();

      await controller.setLocale('en-US');

      expect(saved?.preferredTimeZone, 'Asia/Tokyo');
      expect(saved?.preferredLocale, 'en-US');
    });

    test('clearing the zone saves it as unset', () async {
      AccountPreferences? saved;
      final controller = PreferencesController(
        savePreferences: (preferences) async => saved = preferences,
      );
      await controller.setTimeZone('Europe/Rome');

      await controller.setTimeZone(null);

      expect(controller.timeZone, isNull);
      expect(saved?.preferredTimeZone, isNull);
    });

    test('a failed save still applies the change and says so', () async {
      final controller = PreferencesController(
        savePreferences: (_) async => throw StateError('signed out'),
      );

      final ok = await controller.setTimeZone('Europe/Rome');

      expect(ok, isFalse);
      expect(controller.timeZone, 'Europe/Rome');
    });

    test('an unknown zone or locale counts as unset', () async {
      final controller = PreferencesController(
        loadPreferences: () async => AccountPreferences(),
      );

      await controller.setTimeZone('Mars/Olympus');
      await controller.setLocale('xx-XX');

      expect(controller.timeZone, isNull);
      expect(controller.localeTag, isNull);
    });
  });
}
