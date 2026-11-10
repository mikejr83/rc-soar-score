import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_self_score/l10n/app_localizations.dart';
import 'package:soar_score_self_score/pages/app_info_page.dart';
import 'package:soar_score_self_score/public_site.dart';
import 'package:soar_score_self_score/router.dart';
import 'package:soar_score_self_score/widgets/legal_footer.dart';
import 'package:soar_score_self_score/widgets/self_score_app_bar.dart';

Widget _app(Widget home, {UrlOpener opener = openInBrowser}) =>
    MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: GoRouter(
        routes: [
          GoRoute(path: '/', builder: (context, state) => home),
          GoRoute(
            path: appInfoPath,
            builder: (context, state) => AppInfoPage(opener: opener),
          ),
        ],
      ),
    );

void main() {
  test('open source page points at the self-scoring anchor', () {
    expect(
      openSourcePageUri(base: 'https://rcsoarscore.com').toString(),
      'https://rcsoarscore.com/open-source#self-scoring',
    );
  });

  testWidgets('app bar has one Application info button, no menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const Scaffold(appBar: SelfScoreAppBar(title: 'Contests'))),
    );
    expect(find.byIcon(Icons.more_vert), findsNothing);
    await tester.tap(find.byTooltip('Application info'));
    await tester.pumpAndSettle();
    expect(find.byType(AppInfoPage), findsOneWidget);
    for (final text in [
      'Open source licences',
      'Licences in this app',
      'Privacy Policy',
      'Terms',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
  });

  testWidgets('footer has one link to Application info', (tester) async {
    await tester.pumpWidget(_app(const Scaffold(body: LegalFooter())));
    expect(find.text('Privacy Policy'), findsNothing);
    await tester.tap(find.text('Application info'));
    await tester.pumpAndSettle();
    expect(find.byType(AppInfoPage), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(LegalFooter), findsOneWidget);
  });

  testWidgets('the links open the public site pages', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      _app(
        const SizedBox(),
        opener: (uri) async {
          opened.add(uri);
          return true;
        },
      ),
    );
    final router = GoRouter.of(tester.element(find.byType(SizedBox)));
    router.go(appInfoPath);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open source licences'));
    await tester.tap(find.text('Privacy Policy'));
    await tester.tap(find.text('Terms'));
    expect(opened.map((u) => u.path), ['/open-source', '/privacy', '/terms']);
    expect(opened.first.fragment, 'self-scoring');
  });

  testWidgets(
    'licences fall back to the in-app list when site is unreachable',
    (tester) async {
      await tester.pumpWidget(_app(const SizedBox(), opener: _fail));
      GoRouter.of(tester.element(find.byType(SizedBox))).go(appInfoPath);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open source licences'));
      await tester.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
      expect(find.text('RC Soar Score'), findsWidgets);
    },
  );

  testWidgets('Licences in this app opens the built-in list', (tester) async {
    await tester.pumpWidget(_app(const SizedBox()));
    GoRouter.of(tester.element(find.byType(SizedBox))).go(appInfoPath);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Licences in this app'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('a link that cannot open says so', (tester) async {
    await tester.pumpWidget(_app(const SizedBox(), opener: _fail));
    GoRouter.of(tester.element(find.byType(SizedBox))).go(appInfoPath);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacy Policy'));
    await tester.pump();
    expect(find.textContaining('Could not open the link'), findsOneWidget);
  });

  testWidgets('a thrown opener also says so', (tester) async {
    await tester.pumpWidget(_app(const SizedBox(), opener: _throws));
    GoRouter.of(tester.element(find.byType(SizedBox))).go(appInfoPath);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terms'));
    await tester.pump();
    expect(find.textContaining('Could not open the link'), findsOneWidget);
  });
}

Future<bool> _throws(Uri uri) async => throw Exception('blocked');

Future<bool> _fail(Uri uri) async => false;
