import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/pages/bootstrap_failure_page.dart';
import 'package:soar_score_contest/public_site.dart';

void main() {
  testWidgets(
    'Get support opens the support page beside the recovery controls',
    (tester) async {
      final opened = <Uri>[];
      await tester.pumpWidget(
        MaterialApp(
          home: BootstrapFailurePage(
            error: StateError('Database is unavailable'),
            onRetry: () async {},
            onQuit: () {},
            showQuit: true,
            opener: (uri) async {
              opened.add(uri);
              return true;
            },
          ),
        ),
      );

      expect(find.byKey(const ValueKey('bootstrap-support')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('bootstrap-support')));
      await tester.pumpAndSettle();
      expect(opened, [PublicSite.support]);
      expect(PublicSite.support.toString(), 'https://rcsoarscore.com/support');
    },
  );

  testWidgets('a support link that cannot open says so', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BootstrapFailurePage(
          error: StateError('Database is unavailable'),
          onRetry: () async {},
          onQuit: () {},
          opener: (uri) async => false,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('bootstrap-support')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not open the link'), findsOneWidget);
  });
}
