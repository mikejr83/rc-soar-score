import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/l10n/app_localizations.dart';
import 'package:soar_score_self_score/public_site.dart';
import 'package:soar_score_self_score/widgets/legal_footer.dart';
import 'package:soar_score_self_score/widgets/licences_menu_button.dart';
import 'package:soar_score_self_score/widgets/self_score_app_bar.dart';

Widget _app(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: home,
);

void main() {
  test('open source page points at the self-scoring anchor', () {
    expect(
      openSourcePageUri(base: 'https://rcsoarscore.com').toString(),
      'https://rcsoarscore.com/open-source#self-scoring',
    );
  });

  testWidgets('app bar menu offers the licences in two taps', (tester) async {
    await tester.pumpWidget(
      _app(const Scaffold(appBar: SelfScoreAppBar(title: 'Contests'))),
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Open source licences'), findsOneWidget);
    await tester.tap(find.text('Licences in this app'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('menu entry opens the public site page', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      _app(
        Scaffold(
          appBar: AppBar(
            actions: [
              LicencesMenuButton(
                opener: (uri) async {
                  opened.add(uri);
                  return true;
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open source licences'));
    await tester.pumpAndSettle();
    expect(opened.single.toString(), endsWith('/open-source#self-scoring'));
  });

  testWidgets('footer link opens the public site page', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: LegalFooter(
            opener: (uri) async {
              opened.add(uri);
              return true;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open source licences'));
    await tester.tap(find.text('Privacy Policy'));
    await tester.tap(find.text('Terms'));
    expect(opened.map((u) => u.path), ['/open-source', '/privacy', '/terms']);
    expect(opened.first.fragment, 'self-scoring');
  });

  testWidgets(
    'falls back to the in-app licence list when site is unreachable',
    (tester) async {
      await tester.pumpWidget(
        _app(const Scaffold(body: LegalFooter(opener: _fail))),
      );
      await tester.tap(find.text('Open source licences'));
      await tester.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
    },
  );

  testWidgets('privacy link that cannot open says so', (tester) async {
    await tester.pumpWidget(
      _app(const Scaffold(body: LegalFooter(opener: _fail))),
    );
    await tester.tap(find.text('Privacy Policy'));
    await tester.pump();
    expect(find.textContaining('Could not open the link'), findsOneWidget);
  });

  testWidgets('a thrown opener also says so', (tester) async {
    await tester.pumpWidget(
      _app(const Scaffold(body: LegalFooter(opener: _throws))),
    );
    await tester.tap(find.text('Terms'));
    await tester.pump();
    expect(find.textContaining('Could not open the link'), findsOneWidget);
  });

  testWidgets('the in-app list is named for the app', (tester) async {
    await tester.pumpWidget(
      _app(const Scaffold(body: LegalFooter(opener: _fail))),
    );
    await tester.tap(find.text('Open source licences'));
    await tester.pumpAndSettle();
    expect(find.text('RC Soar Score'), findsWidgets);
  });
}

Future<bool> _throws(Uri uri) async => throw Exception('blocked');

Future<bool> _fail(Uri uri) async => false;
