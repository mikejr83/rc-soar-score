import 'package:go_router/go_router.dart';

import 'pages/contests_page.dart';
import 'pages/home_page.dart';
import 'pages/results_page.dart';
import 'pages/score_entry_page.dart';
import 'pages/team_page.dart';

/// Routes follow `plan/ui/participant-scoring/participant-scoring.md`.
const homePath = '/';
const contestsPath = '/contests';

String contestPath(String contestId) => '/contests/$contestId';
String teamPath(String contestId) => '/contests/$contestId/team';
String resultsPath(String contestId) => '/contests/$contestId/results';
String pilotPath(String contestId, String pilotId) =>
    '/contests/$contestId/pilots/$pilotId';
String scoreEntryPath(String contestId, String pilotId, String roundId) =>
    '/contests/$contestId/pilots/$pilotId/rounds/$roundId';

final router = GoRouter(
  routes: [
    GoRoute(path: homePath, builder: (context, state) => const HomePage()),
    GoRoute(
      path: contestsPath,
      builder: (context, state) => const ContestsPage(),
      routes: [
        // The contest entry route sends a helper to the team overview and a
        // pilot to their pilot overview. Pilot overview is not built yet, so
        // every participant goes to the team overview for now.
        GoRoute(
          path: ':contestId',
          redirect: (context, state) {
            if (state.uri.pathSegments.length > 2) return null;
            return teamPath(state.pathParameters['contestId']!);
          },
          routes: [
            GoRoute(
              path: 'team',
              builder: (context, state) =>
                  TeamPage(contestId: state.pathParameters['contestId']!),
            ),
            GoRoute(
              path: 'results',
              builder: (context, state) =>
                  ResultsPage(contestId: state.pathParameters['contestId']!),
            ),
            GoRoute(
              path: 'pilots/:pilotId/rounds/:roundId',
              builder: (context, state) => ScoreEntryPage(
                contestId: state.pathParameters['contestId']!,
                pilotId: state.pathParameters['pilotId']!,
                roundId: state.pathParameters['roundId']!,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
