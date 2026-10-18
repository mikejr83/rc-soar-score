import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_public/pages/results/results_page.dart';

/// A Wednesday; the coming Sunday is 2026-10-18.
final DateTime now = DateTime(2026, 10, 14, 12);

/// A publication summary as `GET /public/publications` returns it. [start]
/// and [end] are local times; the server sends UTC timestamps.
PublicPublicationSummaryDto summary({
  required String name,
  required DateTime start,
  DateTime? end,
  String? host,
  String? city,
  String? state,
  String? country,
  String? status,
  Id? id,
}) => PublicPublicationSummaryDto(
  publicationId: id ?? Id.create(),
  publishedAt: start.toUtc(),
  projectionRevision: 1,
  contest: {
    'name': name,
    'start': formatUtcTimestamp(start),
    'end': formatUtcTimestamp(end ?? start.add(const Duration(hours: 8))),
    'timezone': 'UTC',
    'host': host,
    'city': city,
    'state': state,
    'country': country,
    'discipline': 'F5J',
    'status': ?status,
  },
  disciplineType: 'f5j',
);

/// Pumps `/results/contests` (and a stub contest route) with a fake loader.
Future<GoRouter> pumpResults(
  WidgetTester tester,
  List<PublicPublicationSummaryDto> data, {
  String location = ResultsPage.path,
  Future<List<PublicPublicationSummaryDto>> Function()? loader,
}) async {
  // Tall enough for the list to build every row; the ListView is lazy.
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: ResultsPage.path,
        // The app wraps every route in the site shell's Scaffold.
        builder: (context, state) => Scaffold(
          body: ResultsPage(
            loader: loader ?? () async => data,
            clock: () => now,
          ),
        ),
      ),
      GoRoute(
        path: '${ResultsPage.path}/:contestId',
        builder: (context, state) =>
            Text('contest ${state.pathParameters['contestId']}'),
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

/// Contest names in list order.
List<String> listedNames(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(find.byType(Text)))
    if (text.data != null && text.data!.startsWith('Contest ')) text.data!,
];
