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
Map<String, Object?> fakePublicationJson({String? contestStatus}) => {
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
    'discipline': 'F5J',
    'status': ?contestStatus,
  },
  'discipline_type': 'F5J',
  'calculation_version': 'f5j-1',
  'results_hidden_through_round': null,
  'participants': [
    _pilot('smith', 'John', 'Smith'),
    _pilot('baker', 'Mike', 'Baker'),
    _pilot('adams', 'Dave', 'Adams'),
    _pilot('waters', 'Chuck', 'Waters'),
  ],
  'teams': <Object?>[],
  'matrix': null,
  'scores': [
    _score(1, 'smith', 1000),
    _score(2, 'smith', 1000),
    _score(3, 'smith', 1000),
    _score(1, 'baker', 998),
    _score(2, 'baker', 998),
    _score(3, 'baker', 998),
    _score(1, 'adams', 998),
    _score(2, 'adams', 998),
    _score(3, 'adams', 850),
    _score(1, 'waters', 900),
    _score(2, 'waters', 990),
    _score(3, 'waters', 990),
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
        'teams': <Object?>[],
      },
      {
        'as_of_round': 2,
        'pilots': [
          _standing('smith', 1, 2000),
          _standing('baker', 2, 1996, tied: true),
          _standing('adams', 2, 1996, tied: true),
          _standing('waters', 4, 1890),
        ],
        'teams': <Object?>[],
      },
      {
        'as_of_round': 3,
        'pilots': [
          _standing('smith', 1, 3000),
          _standing('baker', 2, 2994),
          _standing('waters', 3, 1980, dropped: [1], penalty: 50),
          _standing('adams', 4, 2846),
        ],
        'teams': <Object?>[],
      },
    ],
  },
  'calculation': {'as_of_round': 3, 'computed_at': '2026-10-11T22:00:00Z'},
};

Map<String, Object?> _pilot(String key, String first, String last) => {
  'pilot_key': key,
  'classification': null,
  'number': null,
  'retired_at_round': null,
  'team_key': null,
  'details': {
    'first_name': first,
    'last_name': last,
    'club': null,
    'city': null,
    'state': null,
    'country': 'USA',
  },
};

Map<String, Object?> _score(int round, String key, double points) => {
  'round': round,
  'group': 1,
  'pilot_key': key,
  'outcome': 'flown',
  'raw_points': points,
  'landing_points': 0,
  'penalty_points': 0,
  'group_score': points,
  'selected': true,
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
/// and anything else with 404.
http.Client fakeServer({Map<String, Object?>? publication}) =>
    MockClient((request) async {
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
