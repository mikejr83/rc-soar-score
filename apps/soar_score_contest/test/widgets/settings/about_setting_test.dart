import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:soar_score_contest/public_site.dart';
import 'package:soar_score_contest/widgets/app_version_label.dart';
import 'package:soar_score_contest/widgets/settings/about_setting.dart';

Future<List<Uri>> _pump(WidgetTester tester, {bool succeeds = true}) async {
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
              return succeeds;
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

void main() {
  testWidgets('shows the version and the open source licences entry', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('About'), findsOneWidget);
    expect(find.text('Version 0.1.0-alpha.1'), findsOneWidget);
    expect(find.text('Open source licences'), findsOneWidget);
  });

  testWidgets('the licences entry opens the public page section', (
    tester,
  ) async {
    final opened = await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('about-licences-online')));
    await tester.pumpAndSettle();

    expect(opened, [PublicSite.openSourceLicences]);
    expect(
      PublicSite.openSourceLicences.toString(),
      'https://rcsoarscore.com/open-source#contest-app',
    );
  });

  testWidgets('privacy and terms open their public pages', (tester) async {
    final opened = await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('about-privacy')));
    await tester.tap(find.byKey(const ValueKey('about-terms')));
    await tester.pumpAndSettle();

    expect(opened, [PublicSite.privacyPolicy, PublicSite.termsOfService]);
  });

  testWidgets('a link that cannot open says so', (tester) async {
    await _pump(tester, succeeds: false);

    await tester.tap(find.byKey(const ValueKey('about-licences-online')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not open the link'), findsOneWidget);
  });

  testWidgets('the licences on this device open without a network', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('about-licences-bundled')));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });
}
