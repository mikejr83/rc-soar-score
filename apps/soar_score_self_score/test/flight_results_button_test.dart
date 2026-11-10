import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_self_score/data/sample_data.dart';
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/score_changes.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/l10n/app_localizations.dart';
import 'package:soar_score_self_score/pages/group_results_page.dart';
import 'package:soar_score_self_score/pages/pilot_overview_page.dart';
import 'package:soar_score_self_score/pages/score_entry_page.dart';
import 'package:soar_score_self_score/router.dart';
import 'package:soar_score_self_score/session/guest_session_scope.dart';
import 'package:soar_score_self_score/session/key_value_store.dart';
import 'package:soar_score_self_score/session/score_draft_store.dart';

GoRouter _router() => GoRouter(
  initialLocation: pilotPath(SampleData.contestId, '12'),
  routes: [
    GoRoute(
      path: '/contests/:contestId/pilots/:pilotId',
      builder: (context, state) => PilotOverviewPage(
        contestId: state.pathParameters['contestId']!,
        pilotId: state.pathParameters['pilotId']!,
      ),
      routes: [
        GoRoute(
          path: 'rounds/:roundId',
          builder: (context, state) => ScoreEntryPage(
            contestId: state.pathParameters['contestId']!,
            pilotId: state.pathParameters['pilotId']!,
            roundId: state.pathParameters['roundId']!,
          ),
          routes: [
            GoRoute(
              path: 'group',
              builder: (context, state) => GroupResultsPage(
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

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ScoreDraftScope(
      store: ScoreDraftStore(MemoryKeyValueStore()),
      child: SelfScoreScope(
        repository: SampleSelfScoreRepository(),
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: _router(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => scoreChanges.value = 0);

  testWidgets('Flight Results shows only on rounds with a score', (
    tester,
  ) async {
    await _pump(tester);
    final scored = find.text('View').evaluate().length;
    expect(scored, greaterThan(0));
    expect(find.text('Flight Results'), findsNWidgets(scored));
    // The next round to score has Enter and no results button.
    expect(find.text('Enter'), findsOneWidget);
  });

  testWidgets('Flight Results opens the group and back returns to overview', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Flight Results').first);
    await tester.pumpAndSettle();
    expect(find.byType(GroupResultsPage), findsOneWidget);

    await tester.tap(find.byTooltip('Back to pilot overview'));
    await tester.pumpAndSettle();
    expect(find.byType(GroupResultsPage), findsNothing);
    expect(find.byType(ScoreEntryPage), findsNothing);
    expect(find.byType(PilotOverviewPage), findsOneWidget);
  });
}
