import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/pages/startup_splash_page.dart';
import 'package:soar_score_contest/services/startup/startup_mode.dart';
import 'package:soar_score_contest/services/startup/startup_splash_control.dart';
import 'package:soar_score_contest/widgets/settings/startup_splash_setting.dart';

class _Control implements StartupSplashControl {
  @override
  bool enabled = true;

  /// When set, a write waits for it; a write that throws leaves [enabled].
  Completer<void>? pending;
  bool fail = false;
  int writes = 0;

  @override
  Future<void> setEnabled(bool value) async {
    writes++;
    await pending?.future;
    if (fail) throw StateError('disk full');
    enabled = value;
  }
}

void main() {
  for (final entry in {
    StartupMode.initializing: 'Initializing system...',
    StartupMode.starting: 'Starting...',
    StartupMode.updating: 'Updating system...',
  }.entries) {
    testWidgets('splash says "${entry.value}"', (tester) async {
      await tester.pumpWidget(StartupSplashApp(mode: entry.key));
      await tester.pump();
      expect(find.text(entry.value), findsOneWidget);
    });
  }

  test('the logo follows the system theme', () {
    expect(
      StartupSplashPage.logoAsset(Brightness.light),
      'assets/brand/rc-soar-score-lockup-light.png',
    );
    expect(
      StartupSplashPage.logoAsset(Brightness.dark),
      'assets/brand/rc-soar-score-lockup-dark.png',
    );
  });

  for (final brightness in Brightness.values) {
    testWidgets('splash shows the logo in ${brightness.name} mode', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await tester.pumpWidget(
        const StartupSplashApp(mode: StartupMode.starting),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('startup-splash-logo')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  Widget host(Future<StartupSplashControl?> control) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: StartupSplashSetting(control: control)),
  );

  testWidgets('the setting saves the switch', (tester) async {
    final control = _Control();
    await tester.pumpWidget(host(Future.value(control)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('startup-splash-switch')));
    await tester.pumpAndSettle();
    expect(control.enabled, isFalse);
  });

  testWidgets('no control (web) shows nothing', (tester) async {
    await tester.pumpWidget(host(Future.value(null)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('startup-splash-switch')), findsNothing);
  });

  final switchKey = find.byKey(const ValueKey('startup-splash-switch'));

  for (final startOn in [true, false]) {
    testWidgets(
      'a failed save puts the switch back (${startOn ? 'on' : 'off'})',
      (tester) async {
        final control = _Control()
          ..enabled = startOn
          ..fail = true;
        await tester.pumpWidget(host(Future.value(control)));
        await tester.pumpAndSettle();
        await tester.tap(switchKey);
        await tester.pumpAndSettle();
        expect(tester.widget<SwitchListTile>(switchKey).value, startOn);
        expect(control.enabled, startOn);
        expect(
          find.byKey(const ValueKey('startup-splash-save-failed')),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('taps while a write is pending start no second write', (
    tester,
  ) async {
    final control = _Control()..pending = Completer<void>();
    await tester.pumpWidget(host(Future.value(control)));
    await tester.pumpAndSettle();
    await tester.tap(switchKey);
    await tester.pump();
    expect(tester.widget<SwitchListTile>(switchKey).onChanged, isNull);
    await tester.tap(switchKey, warnIfMissed: false);
    await tester.pump();
    expect(control.writes, 1);
    control.pending!.complete();
    await tester.pumpAndSettle();
    expect(control.enabled, isFalse);
    expect(tester.widget<SwitchListTile>(switchKey).onChanged, isNotNull);
  });
}
