import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_public/app.dart';
import 'package:soar_score_public/pages/results/results_page.dart';
import 'package:soar_score_public/pages/docs/docs_landing_page.dart';
import 'package:soar_score_public/pages/site/landing_page.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

void main() {
  testWidgets('homepage shows logo, description and navigation', (
    tester,
  ) async {
    await tester.pumpWidget(const SoarScorePublicApp());
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(LandingPage),
        matching: find.byType(BrandLogo),
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('RC sailplane soaring contests'),
      findsOneWidget,
    );
    expect(find.byKey(LandingPage.loginLink), findsOneWidget);
    expect(find.text('Login / Registration'), findsOneWidget);
    expect(find.byKey(LandingPage.docsLink), findsOneWidget);
    expect(find.byKey(LandingPage.contestsLink), findsOneWidget);
    expect(LandingPage.loginUrl, startsWith('https://'));

    // External link; the VM stub is a no-op, so this must not throw.
    await tester.tap(find.byKey(LandingPage.loginLink));
    await tester.pumpAndSettle();
    expect(find.byType(LandingPage), findsOneWidget);
  });

  testWidgets('homepage navigation reaches docs and contests', (tester) async {
    await tester.pumpWidget(const SoarScorePublicApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(LandingPage.docsLink));
    await tester.pumpAndSettle();
    expect(find.byType(DocsLandingPage), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.byType(LandingPage), findsOneWidget);

    await tester.tap(find.byKey(LandingPage.contestsLink));
    await tester.pumpAndSettle();
    expect(find.byType(ResultsPage), findsOneWidget);
  });

  testWidgets('homepage navigation is labelled and focusable', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const SoarScorePublicApp());
    await tester.pumpAndSettle();

    for (final (key, label) in [
      (LandingPage.loginLink, 'Login / Registration'),
      (LandingPage.docsLink, 'Documentation / Help'),
      (LandingPage.contestsLink, 'Contests'),
    ]) {
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          label: label,
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
    }
    handle.dispose();
  });
}
