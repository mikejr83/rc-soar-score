import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_public/docs_routes.dart';
import 'package:soar_score_public/pages/docs/competitions_page.dart';
import 'package:soar_score_public/pages/docs/contests_and_scores_page.dart';
import 'package:soar_score_public/pages/docs/docs_landing_page.dart';
import 'package:soar_score_public/pages/docs/docs_not_found_page.dart';
import 'package:soar_score_public/pages/docs/f5j_scoring_page.dart';
import 'package:soar_score_public/pages/docs/participant_scoring_page.dart';
import 'package:soar_score_public/pages/docs/user_accounts_page.dart';
import 'package:soar_score_public/pages/support/support_page.dart';

/// Pumps a router with the docs routes plus a stub for `/results/contests`.
Future<GoRouter> pumpAt(WidgetTester tester, String location) async {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      // The app wraps every route in the site shell's Scaffold.
      ShellRoute(
        builder: (context, state, child) => Scaffold(body: child),
        routes: [
          ...docsRoutes,
          GoRoute(
            path: '/results/contests',
            builder: (context, state) => const Text('contests stub'),
          ),
        ],
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  const pages = <String, Type>{
    '/docs': DocsLandingPage,
    '/docs/competitions': CompetitionsPage,
    '/docs/participant-scoring': ParticipantScoringPage,
    '/docs/participant-scoring/disciplines/f5j': F5jScoringPage,
    '/docs/user-accounts': UserAccountsPage,
    '/docs/contests-and-scores': ContestsAndScoresPage,
    '/docs/not-found': DocsNotFoundPage,
    '/support': SupportPage,
  };

  for (final entry in pages.entries) {
    testWidgets('${entry.key} renders', (tester) async {
      await pumpAt(tester, entry.key);
      expect(find.byType(entry.value), findsOneWidget);
    });
  }

  testWidgets('/help redirects to /docs', (tester) async {
    final router = await pumpAt(tester, '/help');
    expect(find.byType(DocsLandingPage), findsOneWidget);
    expect(router.state.uri.path, '/docs');
  });

  for (final unknown in ['/docs/nope', '/docs/participant-scoring/x/y']) {
    testWidgets('$unknown lands on /docs/not-found', (tester) async {
      final router = await pumpAt(tester, unknown);
      expect(find.byType(DocsNotFoundPage), findsOneWidget);
      expect(router.state.uri.path, DocsNotFoundPage.route);
      expect(find.text('Are you having trouble?'), findsOneWidget);

      await tester.tap(find.text('Go to the support page'));
      await tester.pumpAndSettle();
      expect(find.byType(SupportPage), findsOneWidget);
    });
  }

  const landingLinks = <String, Type>{
    'Contest Director Getting Started': CompetitionsPage,
    'Help Me Enter My Score': ParticipantScoringPage,
    'I Need An Account?': UserAccountsPage,
    'Finding Contests and Results': ContestsAndScoresPage,
    'Request Support': SupportPage,
  };

  for (final entry in landingLinks.entries) {
    testWidgets('landing link "${entry.key}" reaches its page', (tester) async {
      await pumpAt(tester, '/docs');
      await tester.ensureVisible(find.text(entry.key));
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(find.byType(entry.value), findsOneWidget);
    });
  }

  testWidgets('landing link "Search contests" reaches /results/contests', (
    tester,
  ) async {
    await pumpAt(tester, '/docs');
    await tester.tap(find.text('Search contests'));
    await tester.pumpAndSettle();
    expect(find.text('contests stub'), findsOneWidget);
  });

  testWidgets('participant scoring links to the F5J page', (tester) async {
    await pumpAt(tester, '/docs/participant-scoring');
    await tester.tap(find.text('F5J'));
    await tester.pumpAndSettle();
    expect(find.byType(F5jScoringPage), findsOneWidget);
  });
}
