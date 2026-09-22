import 'package:go_router/go_router.dart';

import 'pages/site/docs_page.dart';
import 'pages/site/help_page.dart';
import 'pages/site/landing_page.dart';
import 'pages/results/results_page.dart';

GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Site routes: landing, documentation and help.
      GoRoute(
        path: '/',
        name: 'site_home',
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: '/docs',
        name: 'site_docs',
        builder: (context, state) => const DocsPage(),
      ),
      GoRoute(
        path: '/help',
        name: 'site_help',
        builder: (context, state) => const HelpPage(),
      ),
      // Results routes: contest results browsing (tabular/report UI lands here).
      GoRoute(
        path: '/results',
        name: 'results_listing',
        builder: (context, state) => const ResultsPage(),
      ),
    ],
  );
}
