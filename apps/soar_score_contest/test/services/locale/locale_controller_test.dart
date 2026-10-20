import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/locale/locale_controller.dart';
import 'package:soar_score_core/soar_score_core.dart';

void main() {
  test('a supported tag becomes a locale with its region', () {
    expect(LocaleController().localeFor('en-US'), const Locale('en', 'US'));
  });

  test('no or an unsupported tag follows the device', () {
    expect(LocaleController().localeFor(null), isNull);
    expect(LocaleController().localeFor('xx-XX'), isNull);
  });

  test('load applies the account preference and notifies', () async {
    final controller = LocaleController(
      loadPreferences: () async => AccountPreferences(preferredLocale: 'en-US'),
    );
    var notified = 0;
    controller.addListener(() => notified++);

    await controller.load();

    expect(controller.locale, const Locale('en', 'US'));
    expect(notified, 1);
  });

  test('a failing load leaves the device locale', () async {
    final controller = LocaleController(
      loadPreferences: () async => throw StateError('offline'),
    );

    await controller.load();

    expect(controller.locale, isNull);
  });
}
