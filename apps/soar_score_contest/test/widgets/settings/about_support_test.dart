import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/public_site.dart';
import 'package:soar_score_contest/widgets/app_version_label.dart';
import 'package:soar_score_contest/widgets/settings/about_setting.dart';

void main() {
  testWidgets('About offers Get support, which opens the support page', (tester) async {
    appVersionLoader = () async => '0.1.0-alpha.1';
    addTearDown(() => appVersionLoader = loadAppVersion);
    final opened = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: AboutSetting(
              opener: (uri) async {
                opened.add(uri);
                return true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Get support'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('about-support')));
    await tester.pumpAndSettle();
    expect(opened, [PublicSite.support]);
  });
}
