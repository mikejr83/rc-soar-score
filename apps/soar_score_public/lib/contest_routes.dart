import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/results/contest_view.dart';
import 'pages/results/contest_page.dart';

/// Base of the contest results routes (plan/ui/public-site/view-contest.md).
const String contestResultsBase = '/results/contests';

/// Path of a contest's results, as of [round] when given.
///
/// [contestId] is the spec's name for the path parameter; it carries the
/// publication id that `GET /public/publications/{id}` is keyed by.
String contestResultsPath(String contestId, {int? round}) => round == null
    ? '$contestResultsBase/$contestId'
    : '$contestResultsBase/$contestId/rounds/$round';

/// Path of a contest's Team Scores, as of [round] when given.
String contestTeamResultsPath(String contestId, {int? round}) => round == null
    ? '$contestResultsBase/$contestId/teams/results'
    : '$contestResultsBase/$contestId/teams/results/rounds/$round';

/// Path of a round's Flight Group Scores; `?pilot=` names the pilot whose
/// flight the view scrolls to.
String contestFlightGroupsPath(
  String contestId,
  int round, {
  String? pilotKey,
}) => Uri(
  path: '$contestResultsBase/$contestId/rounds/$round/flight-groups',
  queryParameters: pilotKey == null ? null : {'pilot': pilotKey},
).toString();

/// The contest views, each with and without a round in the path. All are
/// siblings that share one page key, so changing the round or the view keeps
/// the loaded contest instead of stacking a second page.
final List<RouteBase> contestRoutes = [
  GoRoute(
    path: '$contestResultsBase/:contestId',
    name: 'results_contest',
    pageBuilder: (context, state) => _page(state, ContestView.overall),
  ),
  GoRoute(
    path: '$contestResultsBase/:contestId/rounds/:roundNumber',
    name: 'results_contest_round',
    pageBuilder: (context, state) => _page(state, ContestView.overall),
  ),
  GoRoute(
    path: '$contestResultsBase/:contestId/teams/results',
    name: 'results_contest_teams',
    pageBuilder: (context, state) => _page(state, ContestView.teams),
  ),
  GoRoute(
    path: '$contestResultsBase/:contestId/teams/results/rounds/:roundNumber',
    name: 'results_contest_teams_round',
    pageBuilder: (context, state) => _page(state, ContestView.teams),
  ),
  GoRoute(
    path: '$contestResultsBase/:contestId/rounds/:roundNumber/flight-groups',
    name: 'results_contest_flight_groups',
    pageBuilder: (context, state) => _page(state, ContestView.flightGroups),
  ),
];

/// The page key every contest view shares so that moving between them keeps
/// the loaded contest.
LocalKey contestPageKey(String contestId) =>
    ValueKey('results_contest_$contestId');

Page<void> _page(GoRouterState state, ContestView view) {
  final contestId = state.pathParameters['contestId']!;
  return MaterialPage(
    key: contestPageKey(contestId),
    child: ContestPage(
      contestId: contestId,
      view: view,
      round: int.tryParse(state.pathParameters['roundNumber'] ?? ''),
      pilotKey: state.uri.queryParameters['pilot'],
    ),
  );
}
