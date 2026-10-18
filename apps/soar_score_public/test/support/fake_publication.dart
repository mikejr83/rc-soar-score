import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_public/api_client_provider.dart';
import 'package:soar_score_public/contest_routes.dart';

/// The publication id the fake server knows.
const String fakeContestId = '019c0000-0000-7000-8000-000000000030';

/// A three-round F5J contest with four pilots, in the shape of
/// `GET /public/publications/{id}`.
///
/// - Smith wins every round. Baker and Adams tie for second after round 2.
/// - Waters flies 900, 990, 990; as of round 3 round 1 is dropped, as of
///   round 2 nothing is.
/// - Adams falls to fourth in round 3.
/// - Teams: the Eagles (Smith, Adams) lead the Hawks (Baker, Waters);
///   `teams: false` makes a contest without teams.
/// - Round 3 flies in two groups; Waters' group 2 flight is replaced by a
///   re-flight, and its scores carry raw components (#456, #457).
/// - [discipline] is the `discipline_type`; F3K has no landing column.
Map<String, Object?> fakePublicationJson({
  String? contestStatus,
  bool teams = true,
  String discipline = 'F5J',
}) => {
  'publication_id': fakeContestId,
  'visibility': 'Public',
  'projection_revision': 1,
  'published_at': '2026-10-17T14:00:00Z',
  'contest': {
    'name': 'Front Range ALES Open',
    'start': '2026-10-10T14:00:00Z',
    'end': '2026-10-11T22:00:00Z',
    'timezone': 'America/Denver',
    'host': 'Front Range Soaring',
    'city': 'Boulder',
    'state': 'CO',
    'country': 'USA',
    'discipline': discipline,
    'status': ?contestStatus,
  },
  'discipline_type': discipline,
  'calculation_version': 'f5j-1',
  'results_hidden_through_round': null,
  'participants': [
    _pilot('smith', 'John', 'Smith', team: teams ? 'eagles' : null),
    _pilot('baker', 'Mike', 'Baker', team: teams ? 'hawks' : null),
    _pilot('adams', 'Dave', 'Adams', team: teams ? 'eagles' : null),
    _pilot('waters', 'Chuck', 'Waters', team: teams ? 'hawks' : null),
  ],
  'teams': [
    if (teams) ...[
      {
        'team_key': 'eagles',
        'name': 'Eagles',
        'pilots': ['adams', 'smith'],
      },
      {
        'team_key': 'hawks',
        'name': 'Hawks',
        'pilots': ['baker', 'waters'],
      },
    ],
  ],
  'matrix': null,
  'scores': [
    _score(1, 'smith', 1000),
    _score(2, 'smith', 1000),
    _score(3, 'smith', 1000, time: 600, height: 120),
    _score(1, 'baker', 998),
    _score(2, 'baker', 998),
    _score(3, 'baker', 998, time: 598.8, height: 122),
    _score(1, 'adams', 998),
    _score(2, 'adams', 998),
    _score(3, 'adams', 850, group: 2, time: 510, height: 140),
    _score(1, 'waters', 900),
    _score(2, 'waters', 990),
    _score(3, 'waters', 400, group: 2, selected: false, time: 240, height: 135),
    _score(3, 'waters', 990, group: 2, reflight: 1, time: 594, height: 118),
  ],
  'standings': {
    'rounds': [
      {
        'as_of_round': 1,
        'pilots': [
          _standing('smith', 1, 1000),
          _standing('baker', 2, 998, tied: true),
          _standing('adams', 2, 998, tied: true),
          _standing('waters', 4, 900),
        ],
        'teams': [
          if (teams) ...[_team('eagles', 1, 1998), _team('hawks', 2, 1898)],
        ],
      },
      {
        'as_of_round': 2,
        'pilots': [
          _standing('smith', 1, 2000),
          _standing('baker', 2, 1996, tied: true),
          _standing('adams', 2, 1996, tied: true),
          _standing('waters', 4, 1890),
        ],
        'teams': [
          if (teams) ...[_team('eagles', 1, 3996), _team('hawks', 2, 3886)],
        ],
      },
      {
        'as_of_round': 3,
        'pilots': [
          _standing('smith', 1, 3000),
          _standing('baker', 2, 2994),
          _standing('waters', 3, 1980, dropped: [1], penalty: 50),
          _standing('adams', 4, 2846),
        ],
        'teams': [
          if (teams) ...[_team('eagles', 1, 5846), _team('hawks', 2, 4974)],
        ],
      },
    ],
  },
  'calculation': {'as_of_round': 3, 'computed_at': '2026-10-11T22:00:00Z'},
};

Map<String, Object?> _pilot(
  String key,
  String first,
  String last, {
  String? team,
}) => {
  'pilot_key': key,
  'classification': null,
  'number': null,
  'retired_at_round': null,
  'team_key': team,
  'details': {
    'first_name': first,
    'last_name': last,
    'club': null,
    'city': null,
    'state': null,
    'country': 'USA',
  },
};

Map<String, Object?> _score(
  int round,
  String key,
  double points, {
  int group = 1,
  bool selected = true,
  int? reflight,
  double? time,
  double? height,
}) => {
  'round': round,
  'group': group,
  'pilot_key': key,
  'outcome': 'flown',
  'raw_points': points,
  'landing_points': 0,
  'penalty_points': 0,
  'group_score': points,
  'selected': selected,
  'preliminary': false,
  // Provisional keys from #457 and #456; see PublishedContest.
  'reflight': ?reflight,
  if (time != null)
    'raw_components': {'time_flown': time, 'launch_height': height},
};

Map<String, Object?> _team(String key, int place, double score) => {
  'team_key': key,
  'place': place,
  'tied': false,
  'team_score': score,
  'counted_pilots': key == 'eagles' ? ['adams', 'smith'] : ['baker', 'waters'],
  'preliminary': false,
};

Map<String, Object?> _standing(
  String key,
  int place,
  double overall, {
  bool tied = false,
  List<int> dropped = const [],
  double penalty = 0,
}) => {
  'pilot_key': key,
  'place': place,
  'tied': tied,
  'raw_total': overall + penalty,
  'dropped_rounds': dropped,
  'penalty_total': penalty,
  'overall_score': overall,
  'preliminary': false,
};

/// Answers `GET /public/publications/{fakeContestId}` with [publication]
/// and anything else with 404. [onRequest] sees every request.
http.Client fakeServer({
  Map<String, Object?>? publication,
  void Function()? onRequest,
}) => MockClient((request) async {
  onRequest?.call();
  if (request.url.path == '/public/publications/$fakeContestId') {
    return http.Response(
      jsonEncode(publication ?? fakePublicationJson()),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
  return http.Response(
    jsonEncode({
      'error': {'code': 'not_found', 'message': 'no such publication'},
    }),
    404,
    headers: {'content-type': 'application/json'},
  );
});

/// Pumps the contest routes at [location] against [client] (the fake server
/// when null) and settles.
Future<GoRouter> pumpContestRoutes(
  WidgetTester tester,
  String location, {
  http.Client? client,
}) async {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      ShellRoute(
        builder: (context, state, child) => Scaffold(body: child),
        routes: [
          GoRoute(
            path: '/results/contests',
            builder: (context, state) => const Text('contests stub'),
          ),
          ...contestRoutes,
        ],
      ),
    ],
  );
  await tester.pumpWidget(
    ApiClientInherited(
      client: ApiClient(
        baseUrl: Uri.parse('http://fake'),
        httpClient: client ?? fakeServer(),
      ),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}
