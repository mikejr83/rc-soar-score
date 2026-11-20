import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/l10n/app_localization_delegates.dart';
import 'package:soar_score_self_score/l10n/app_localizations.dart';
import 'package:soar_score_self_score/public_site.dart';
import 'package:soar_score_self_score/widgets/load_error_view.dart';

void main() {
  test(
    'the support page is the public site form and carries no credential',
    () {
      final uri = supportPageUri(base: 'https://rcsoarscore.com');
      expect(uri.toString(), 'https://rcsoarscore.com/support');
      expect(uri.hasQuery, isFalse);
      expect(uri.fragment, isEmpty);
      expect(
        supportPageUri(base: 'https://preview.example.test').host,
        'preview.example.test',
      );
    },
  );

  testWidgets('a load error offers Get support and Retry still works', (
    tester,
  ) async {
    final opened = <Uri>[];
    var retried = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: LoadErrorView(
            message: 'Could not load the invitation.',
            onRetry: () => retried++,
            supportUri: supportPageUri(base: 'https://rcsoarscore.com'),
            supportLabel: 'Get support',
            opener: (uri) async {
              opened.add(uri);
              return true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('load-error-support')));
    await tester.pumpAndSettle();
    expect(opened, [Uri.parse('https://rcsoarscore.com/support')]);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(retried, 1);
  });

  testWidgets('without a support page the error view has no support action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoadErrorView(message: 'Failed', onRetry: () {}),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('load-error-support')), findsNothing);
  });
}
