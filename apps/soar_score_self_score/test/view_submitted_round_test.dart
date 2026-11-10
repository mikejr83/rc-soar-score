import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_self_score/data/sample_data.dart';
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/score_changes.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/l10n/app_localizations.dart';
import 'package:soar_score_self_score/models/entry_context.dart';
import 'package:soar_score_self_score/models/pilot_overview.dart';
import 'package:soar_score_self_score/models/pilot_round.dart';
import 'package:soar_score_self_score/pages/group_results_page.dart';
import 'package:soar_score_self_score/pages/pilot_overview_page.dart';
import 'package:soar_score_self_score/pages/score_entry_page.dart';
import 'package:soar_score_self_score/router.dart';
import 'package:soar_score_self_score/session/guest_session_scope.dart';
import 'package:soar_score_self_score/session/key_value_store.dart';
import 'package:soar_score_self_score/session/score_draft_store.dart';

/// The sample rounds with a pending-review round (3) beside the submitted
/// ones, as the server would answer them.
class _Repository extends SampleSelfScoreRepository {
  _Repository({this.access = ScoringAccess.open});

  final ScoringAccess access;

  @override
  Future<PilotOverview> pilotOverview(String contestId, String pilotId) async {
    final base = await super.pilotOverview(contestId, pilotId);
    return PilotOverview(
      contestName: base.contestName,
      teamName: base.teamName,
      pilotName: base.pilotName,
      pilotNumber: base.pilotNumber,
      access: access,
      rounds: [
        for (final round in base.rounds)
          switch (round.number) {
            // The sample round 3 is pendingReview; round 4 is nextToScore.
            3 => PilotRound(
              number: 3,
              group: round.group,
              lane: round.lane,
              status: PilotRoundStatus.pendingReview,
              enteredBy: 'you',
            ),
            4 => PilotRound(
              number: 4,
              group: round.group,
              lane: round.lane,
              status: access == ScoringAccess.open
                  ? PilotRoundStatus.nextToScore
                  : PilotRoundStatus.locked,
            ),
            _ => round,
          },
      ],
    );
  }

  @override
  Future<EntryContext> entryContext(
    String contestId,
    String pilotId,
    int round,
  ) async {
    final base = await super.entryContext(contestId, pilotId, round);
    // A score already exists, so the form opens read-only.
    return EntryContext(
      pilotName: base.pilotName,
      pilotNumber: base.pilotNumber,
      round: base.round,
      roundCount: base.roundCount,
      group: base.group,
      lane: base.lane,
      landingTable: base.landingTable,
      matrixRevision: base.matrixRevision,
      alreadySubmitted: true,
      submittedScore: const SubmittedScore(
        components: {'time_flown': 390.4, 'launch_height': 45},
      ),
    );
  }
}

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

late GoRouter appRouter;

Future<void> _pump(WidgetTester tester, _Repository repository) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  appRouter = _router();
  await tester.pumpWidget(
    ScoreDraftScope(
      store: ScoreDraftStore(MemoryKeyValueStore()),
      child: SelfScoreScope(
        repository: repository,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: appRouter,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Taps the View button of the card for [round] and checks the score entry
/// page opened read-only.
Future<void> _expectReadOnlyEntry(WidgetTester tester, int round) async {
  final card = find.ancestor(
    of: find.text('Round $round'),
    matching: find.byType(Card),
  );
  await tester.tap(find.descendant(of: card, matching: find.text('View')));
  await tester.pumpAndSettle();
  // The tap pushes, which does not move the route information provider; the
  // current configuration carries the new page.
  final top = appRouter.routerDelegate.currentConfiguration.matches.last;
  expect(
    top.matchedLocation,
    scoreEntryPath(SampleData.contestId, '12', '$round'),
  );
  // The stored values show and nothing can be sent.
  expect(find.text('Time flown'), findsOneWidget);
  expect(find.text('Submit score'), findsNothing);
  await tester.scrollUntilVisible(
    find.text('See group results'),
    -400,
    scrollable: find.byType(Scrollable).first,
  );
  expect(find.text('See group results'), findsOneWidget);
}

void main() {
  setUp(() => scoreChanges.value = 0);

  testWidgets('View on a pending-review round opens the read-only entry page', (
    tester,
  ) async {
    await _pump(tester, _Repository());
    // Round 3 is pending review; its View button sits above the Enter one.
    expect(find.text('Pending review'), findsOneWidget);
    expect(find.text('View'), findsWidgets);
    await _expectReadOnlyEntry(tester, 3);
  });

  testWidgets('View on a submitted round works when scoring is closed', (
    tester,
  ) async {
    await _pump(tester, _Repository(access: ScoringAccess.closed));
    // A submitted round keeps View when the contest no longer takes scores;
    // the next round is locked instead.
    expect(find.text('Scoring closed'), findsOneWidget);
    expect(find.text('View'), findsWidgets);
    await _expectReadOnlyEntry(tester, 1);
  });
}
