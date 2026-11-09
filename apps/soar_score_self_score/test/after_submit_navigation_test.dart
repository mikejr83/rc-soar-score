import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_self_score/data/sample_data.dart';
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/score_changes.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/l10n/app_localizations.dart';
import 'package:soar_score_self_score/models/pilot_overview.dart';
import 'package:soar_score_self_score/models/pilot_round.dart';
import 'package:soar_score_self_score/models/score_submission.dart';
import 'package:soar_score_self_score/pages/pilot_overview_page.dart';
import 'package:soar_score_self_score/pages/score_entry_page.dart';
import 'package:soar_score_self_score/router.dart';
import 'package:soar_score_self_score/session/guest_session_scope.dart';
import 'package:soar_score_self_score/session/key_value_store.dart';
import 'package:soar_score_self_score/session/score_draft_store.dart';

/// Accepts the score, and from then on reports round 4 as submitted.
class _Repository extends SampleSelfScoreRepository {
  bool accepted = false;
  int overviewLoads = 0;

  @override
  Future<SubmitResult> submitScore(ScoreSubmission submission) async {
    accepted = true;
    return const ScoreAccepted(flightScore: '962.5');
  }

  @override
  Future<PilotOverview> pilotOverview(String contestId, String pilotId) async {
    overviewLoads++;
    final base = await super.pilotOverview(contestId, pilotId);
    return PilotOverview(
      contestName: base.contestName,
      teamName: base.teamName,
      pilotName: base.pilotName,
      pilotNumber: base.pilotNumber,
      rounds: [
        for (final round in base.rounds)
          if (accepted && round.number == 4)
            PilotRound(
              number: 4,
              group: round.group,
              lane: round.lane,
              status: PilotRoundStatus.submitted,
              enteredBy: 'you',
            )
          else
            round,
      ],
    );
  }
}

/// The app's nested routes, with a stub for the group results page.
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
              builder: (context, state) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () =>
                        context.go(pilotPath(SampleData.contestId, '12')),
                    child: const Text('Group stub back'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

Future<_Repository> _submitRoundFour(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repository = _Repository();
  await tester.pumpWidget(
    ScoreDraftScope(
      store: ScoreDraftStore(MemoryKeyValueStore()),
      child: SelfScoreScope(
        repository: repository,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: _router(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(repository.overviewLoads, 1);

  await tester.tap(find.text('Enter'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).at(0), '630.4');
  await tester.enterText(find.byType(TextField).at(1), '45');
  await tester.tap(find.text('Choose landing'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Good'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Submit score'));
  await tester.pumpAndSettle();
  expect(find.text('See group results'), findsOneWidget);
  return repository;
}

void main() {
  setUp(() => scoreChanges.value = 0);

  testWidgets('See group results, then back, shows the round submitted', (
    tester,
  ) async {
    final repository = await _submitRoundFour(tester);

    await tester.tap(find.text('See group results'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Group stub back'));
    await tester.pumpAndSettle();

    expect(find.text('Enter'), findsNothing);
    expect(find.text('Submitted'), findsWidgets);
    // The first load, and one reload when the score was accepted.
    expect(repository.overviewLoads, 2);
  });

  testWidgets('All rounds from the entry page shows the round submitted', (
    tester,
  ) async {
    final repository = await _submitRoundFour(tester);

    await tester.tap(find.textContaining('All rounds for'));
    await tester.pumpAndSettle();

    expect(find.text('Enter'), findsNothing);
    expect(repository.overviewLoads, 2);
  });

  testWidgets('the app bar back returns to an up-to-date overview', (
    tester,
  ) async {
    final repository = await _submitRoundFour(tester);

    await tester.tap(find.byTooltip('Back to pilot overview'));
    await tester.pumpAndSettle();

    expect(find.text('Enter'), findsNothing);
    expect(repository.overviewLoads, 2);
  });
}
