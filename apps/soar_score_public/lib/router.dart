import 'package:go_router/go_router.dart';

import 'docs_routes.dart';
import 'pages/results/results_page.dart';
import 'pages/site/landing_page.dart';
import 'pages/site/not_found_page.dart';
import 'widgets/site_shell.dart';

GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) =>
        SiteShell(child: NotFoundPage(location: state.uri.path)),
    routes: [
      ShellRoute(
        builder: (context, state, child) => SiteShell(child: child),
        routes: [
          // Site routes: landing, documentation and help.
          GoRoute(
            path: '/',
            name: 'site_home',
            builder: (context, state) => const LandingPage(),
          ),
          ...docsRoutes,
          // Results routes: contest search and results (#434 to #436).
          GoRoute(path: '/results', redirect: (_, _) => '/results/contests'),
          GoRoute(
            path: '/results/contests',
            name: 'results_contests',
            builder: (context, state) => const ResultsPage(),
          ),
        ],
      ),
    ],
  );
}
