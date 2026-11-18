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

  @override
  Future<void> setEnabled(bool value) async => enabled = value;
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
      'assets/brand/rc-soar-score-lockup-light-transparent.svg',
    );
    expect(
      StartupSplashPage.logoAsset(Brightness.dark),
      'assets/brand/rc-soar-score-lockup-dark-transparent.svg',
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
}
