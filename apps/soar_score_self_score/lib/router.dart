import 'package:go_router/go_router.dart';

import 'pages/contests_page.dart';
import 'pages/home_page.dart';
import 'pages/results_page.dart';
import 'pages/score_entry_page.dart';
import 'pages/team_page.dart';

const homePath = '/';
const contestsPath = '/contests';
const teamPath = '/team';
const scoresPath = '/scores';
const resultsPath = '/results';

final router = GoRouter(
  routes: [
    GoRoute(path: homePath, builder: (context, state) => const HomePage()),
    GoRoute(
      path: contestsPath,
      builder: (context, state) => const ContestsPage(),
    ),
    GoRoute(path: teamPath, builder: (context, state) => const TeamPage()),
    GoRoute(
      path: scoresPath,
      builder: (context, state) => const ScoreEntryPage(),
    ),
    GoRoute(
      path: resultsPath,
      builder: (context, state) => const ResultsPage(),
    ),
  ],
);
