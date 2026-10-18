import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_public/app.dart';
import 'package:soar_score_public/pages/docs/docs_landing_page.dart';
import 'package:soar_score_public/pages/results/results_page.dart';
import 'package:soar_score_public/pages/site/landing_page.dart';
import 'package:soar_score_public/widgets/site_shell.dart';

void main() {
  testWidgets('every route renders inside the site shell', (tester) async {
    await tester.pumpWidget(const SoarScorePublicApp());
    await tester.pumpAndSettle();
    expect(find.byType(SiteShell), findsOneWidget);
    expect(find.byType(LandingPage), findsOneWidget);

    final router = GoRouter.of(tester.element(find.byType(LandingPage)));
    for (final (location, page) in [
      ('/docs', DocsLandingPage),
      ('/help', DocsLandingPage),
      ('/results/contests', ResultsPage),
      ('/', LandingPage),
    ]) {
      router.go(location);
      await tester.pumpAndSettle();
      expect(find.byType(SiteShell), findsOneWidget, reason: location);
      expect(find.byType(page), findsOneWidget, reason: location);
    }
  });

  testWidgets('/results redirects to /results/contests', (tester) async {
    await tester.pumpWidget(const SoarScorePublicApp());
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.byType(LandingPage)));
    router.go('/results');
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/results/contests');
    expect(find.byType(ResultsPage), findsOneWidget);
  });

  testWidgets('shell navigation reaches each route', (tester) async {
    await tester.pumpWidget(const SoarScorePublicApp());
    await tester.pumpAndSettle();

    for (final (key, page) in [
      (SiteShell.docsLink, DocsLandingPage),
      (SiteShell.helpLink, DocsLandingPage),
      (SiteShell.contestsLink, ResultsPage),
      (SiteShell.homeLink, LandingPage),
    ]) {
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(find.byType(page), findsOneWidget);
    }
  });

  testWidgets('shell navigation is labelled and focusable', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const SoarScorePublicApp());
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('RC Soar Score logo'), findsWidgets);
    for (final (key, label) in [
      (SiteShell.homeLink, 'Home'),
      (SiteShell.docsLink, 'Docs'),
      (SiteShell.helpLink, 'Help'),
      (SiteShell.contestsLink, 'Contests'),
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
