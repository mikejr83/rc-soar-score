import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:soar_score_contest/app.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/services/locale/locale_controller.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import '../support/fake_bootstrap.dart';

/// A test-only second app locale: it overrides one message and leaves the
/// rest to the English text, as a partial translation does.
class _AppLocalizationsXx extends AppLocalizationsEn {
  _AppLocalizationsXx() : super('xx');

  @override
  String get panelsHeading => 'Xx panels';
}

class _XxDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _XxDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'xx';

  @override
  Future<AppLocalizations> load(Locale locale) async => _AppLocalizationsXx();

  @override
  bool shouldReload(_XxDelegate old) => false;
}

/// Supplies a framework localization for any locale, so a locale the
/// framework does not ship can still run the Material widgets.
class _AnyLocale<T> extends LocalizationsDelegate<T> {
  const _AnyLocale(this._value);

  final T _value;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<T> load(Locale locale) => SynchronousFuture(_value);

  @override
  bool shouldReload(_AnyLocale<T> old) => false;
}

Future<void> _pump(WidgetTester tester, LocaleController locale) async {
  await tester.pumpWidget(
    SoarScoreContestApp(
      bootstrap: FakeBootstrap(BackendLocalUiStore(MemoryLocalUiBackend())),
      routerInitialLocation: settingsPath,
      localeController: locale,
      extraSupportedLocales: const [Locale('xx')],
      extraLocalizationDelegates: const [
        _XxDelegate(),
        _AnyLocale<MaterialLocalizations>(DefaultMaterialLocalizations()),
        _AnyLocale<CupertinoLocalizations>(DefaultCupertinoLocalizations()),
        _AnyLocale<WidgetsLocalizations>(DefaultWidgetsLocalizations()),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

LocaleController _preferring(String tag) =>
    LocaleController(isSupported: (t) => t == tag || t == 'en-US')
      ..setPreferred(tag);

void main() {
  testWidgets('a second locale overrides the messages it translates', (
    tester,
  ) async {
    await _pump(tester, _preferring('xx'));

    expect(find.text('Xx panels'), findsOneWidget);
    expect(find.text('Panels'), findsNothing);
  });

  testWidgets('messages the second locale leaves out fall back to English', (
    tester,
  ) async {
    await _pump(tester, _preferring('xx'));

    expect(find.text(AppLocalizationsEn().panelsResetButton), findsOneWidget);
  });

  testWidgets('English still shows its own text', (tester) async {
    await _pump(tester, _preferring('en-US'));

    expect(find.text('Panels'), findsOneWidget);
  });
}
