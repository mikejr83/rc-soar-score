import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/pages/landing_editor_page.dart';
import 'package:soar_score_contest/pages/landings_page.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'participant_test_support.dart';

/// A landing table view with the entries `(key, points)`; `system` tables
/// have no owner.
LandingTableView landingView(
  String name,
  int n, {
  bool system = false,
  bool inUse = false,
  LandingInputUnit unit = LandingInputUnit.meters,
  List<(String, int)> entries = const [('within_1m', 10), ('within_2m', 5)],
}) {
  final id = Id.parse('019c0000-0000-7000-8000-00000000010$n');
  return LandingTableView(
    content: LandingTableWithResults(
      table: LandingTable(
        id: id,
        ownerAccountId: system ? null : Id.parse(ownerId),
        name: name,
        inputUnit: unit,
        createdAt: DateTime.utc(2026, 9),
      ),
      results: [
        for (final (i, (key, points)) in entries.indexed)
          LandingResult(
            id: Id.parse('019c0000-0000-7000-8000-0000000002$n$i'),
            landingTableId: id,
            entryKey: key,
            displayValue: 'Label $key',
            pointValue: points,
            ordinalPosition: i + 1,
          ),
      ],
    ),
    inUse: inUse,
  );
}

Map<String, Object?> landingList(List<LandingTableView> views) => {
  'landing_tables': [for (final view in views) view.toJson()],
};

/// Pumps the landing routes (list and form) under [client].
Widget landingsApp(ApiClient client, {String initial = landingsPath}) {
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: landingsPath,
        builder: (_, _) => const Scaffold(body: LandingsPage()),
      ),
      GoRoute(
        path: newLandingPath,
        builder: (_, state) => Scaffold(
          body: LandingEditorPage(
            source: state.extra is LandingTableView
                ? state.extra as LandingTableView
                : null,
          ),
        ),
      ),
    ],
  );
  return ApiClientInherited(
    client: client,
    child: MaterialApp.router(routerConfig: router),
  );
}
