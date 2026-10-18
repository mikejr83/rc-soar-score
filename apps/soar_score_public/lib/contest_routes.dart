import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

/// `/results/contests/:contestId` and `.../rounds/:roundNumber`: the same
/// page, with the selected round taken from the path. Both are siblings that
/// share one page key, so changing the round keeps the loaded contest instead
/// of stacking a second page. #436 adds its team and flight-group views as
/// further siblings.
final List<RouteBase> contestRoutes = [
  GoRoute(
    path: '$contestResultsBase/:contestId',
    name: 'results_contest',
    pageBuilder: (context, state) => _page(state),
  ),
  GoRoute(
    path: '$contestResultsBase/:contestId/rounds/:roundNumber',
    name: 'results_contest_round',
    pageBuilder: (context, state) => _page(state),
  ),
];

/// The page key every contest view shares so that moving between them keeps
/// the loaded contest (#436 uses it for the team and flight-group pages).
LocalKey contestPageKey(String contestId) =>
    ValueKey('results_contest_$contestId');

Page<void> _page(GoRouterState state) {
  final contestId = state.pathParameters['contestId']!;
  return MaterialPage(
    key: contestPageKey(contestId),
    child: ContestPage(
      contestId: contestId,
      round: int.tryParse(state.pathParameters['roundNumber'] ?? ''),
    ),
  );
}
