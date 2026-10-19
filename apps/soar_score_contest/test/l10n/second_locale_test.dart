import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:soar_score_contest/widgets/settings/reset_areas_setting.dart';

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

Future<void> _pump(WidgetTester tester, Locale locale) async {
  const body = Scaffold(body: ResetAreasSetting(controller: null));
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      // The second locale takes over the app's own messages only.
      home: locale.languageCode == 'xx'
          ? Builder(
              builder: (context) => Localizations.override(
                context: context,
                locale: locale,
                delegates: const [_XxDelegate()],
                child: body,
              ),
            )
          : body,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a second locale overrides the messages it translates', (
    tester,
  ) async {
    await _pump(tester, const Locale('xx'));

    expect(find.text('Xx panels'), findsOneWidget);
    expect(find.text('Panels'), findsNothing);
  });

  testWidgets('messages the second locale leaves out fall back to English', (
    tester,
  ) async {
    await _pump(tester, const Locale('xx'));

    expect(find.text(AppLocalizationsEn().panelsResetButton), findsOneWidget);
  });

  testWidgets('English still shows its own text', (tester) async {
    await _pump(tester, const Locale('en'));

    expect(find.text('Panels'), findsOneWidget);
  });
}
