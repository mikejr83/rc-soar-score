import 'package:go_router/go_router.dart';

import 'pages/docs/competitions_page.dart';
import 'pages/docs/contests_and_scores_page.dart';
import 'pages/docs/docs_landing_page.dart';
import 'pages/docs/docs_not_found_page.dart';
import 'pages/docs/f5j_scoring_page.dart';
import 'pages/docs/participant_scoring_page.dart';
import 'pages/docs/user_accounts_page.dart';
import 'pages/support/support_page.dart';

/// Documentation, help and support routes (plan/ui/public-site/docs-help.md).
final List<RouteBase> docsRoutes = [
  GoRoute(
    path: '/docs',
    name: 'docs',
    builder: (context, state) => const DocsLandingPage(),
    routes: [
      GoRoute(
        path: 'competitions',
        name: 'docs_competitions',
        builder: (context, state) => const CompetitionsPage(),
      ),
      GoRoute(
        path: 'participant-scoring',
        name: 'docs_participant_scoring',
        builder: (context, state) => const ParticipantScoringPage(),
        routes: [
          // Static page per discipline, not a dynamic parameter (spec).
          GoRoute(
            path: 'disciplines/f5j',
            name: 'docs_f5j',
            builder: (context, state) => const F5jScoringPage(),
          ),
        ],
      ),
      GoRoute(
        path: 'user-accounts',
        name: 'docs_user_accounts',
        builder: (context, state) => const UserAccountsPage(),
      ),
      GoRoute(
        path: 'contests-and-scores',
        name: 'docs_contests_and_scores',
        builder: (context, state) => const ContestsAndScoresPage(),
      ),
      GoRoute(
        path: 'not-found',
        name: 'docs_not_found',
        builder: (context, state) => const DocsNotFoundPage(),
      ),
      // Anything else under /docs lands on the docs not-found page.
      GoRoute(
        path: ':rest(.*)',
        redirect: (context, state) => DocsNotFoundPage.route,
      ),
    ],
  ),
  // The spec uses /docs for help; /help only redirects there.
  GoRoute(path: '/help', redirect: (context, state) => DocsLandingPage.route),
  GoRoute(
    path: '/support',
    name: 'support',
    builder: (context, state) => const SupportPage(),
  ),
];
