import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_self_score/data/sample_data.dart';
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/l10n/app_localizations.dart';
import 'package:soar_score_self_score/models/entry_context.dart';
import 'package:soar_score_self_score/pages/score_entry_page.dart';
import 'package:soar_score_self_score/router.dart';
import 'package:soar_score_self_score/session/guest_session_scope.dart';
import 'package:soar_score_self_score/session/key_value_store.dart';
import 'package:soar_score_self_score/session/score_draft_store.dart';

/// Rounds 1 to 3 hold a score; each load takes a moment, as a request does.
class _Repository extends SampleSelfScoreRepository {
  @override
  Future<EntryContext> entryContext(
    String contestId,
    String pilotId,
    int round,
  ) async {
    final base = await super.entryContext(contestId, pilotId, round);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final scored = round < 4;
    return EntryContext(
      pilotName: base.pilotName,
      pilotNumber: base.pilotNumber,
      round: base.round,
      roundCount: base.roundCount,
      lastOpenRound: base.lastOpenRound,
      group: base.group,
      lane: base.lane,
      landingTable: base.landingTable,
      matrixRevision: base.matrixRevision,
      alreadySubmitted: scored,
      submittedScore: scored
          ? SubmittedScore(
              components: {'time_flown': 300.0 + round, 'launch_height': 40},
            )
          : null,
    );
  }
}

Future<GoRouter> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: scoreEntryPath(SampleData.contestId, '12', '2'),
    routes: [
      GoRoute(
        path: '/contests/:contestId/pilots/:pilotId/rounds/:roundId',
        builder: (context, state) => ScoreEntryPage(
          contestId: state.pathParameters['contestId']!,
          pilotId: state.pathParameters['pilotId']!,
          roundId: state.pathParameters['roundId']!,
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ScoreDraftScope(
      store: ScoreDraftStore(MemoryKeyValueStore()),
      child: SelfScoreScope(
        repository: _Repository(),
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

bool _enabled(WidgetTester tester, String tooltip) =>
    tester
        .widget<IconButton>(
          find.widgetWithIcon(
            IconButton,
            tooltip == 'next' ? Icons.chevron_right : Icons.chevron_left,
          ),
        )
        .onPressed !=
    null;

void main() {
  testWidgets('moving between rounds shows each round\'s own score', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('502'), findsOneWidget);

    await tester.tap(find.byTooltip('Next round'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Round 3'), findsOneWidget);
    expect(find.text('503'), findsOneWidget);
    expect(find.text('502'), findsNothing);

    // Round 4 has no score yet: an empty, editable form.
    await tester.tap(find.byTooltip('Next round'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Round 4'), findsOneWidget);
    expect(find.text('503'), findsNothing);

    await tester.tap(find.byTooltip('Previous round'));
    await tester.pumpAndSettle();
    expect(find.text('503'), findsOneWidget);
  });

  testWidgets('next stops at the round that is next to score', (tester) async {
    await _pump(tester);
    await tester.tap(find.byTooltip('Next round'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next round'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Round 4'), findsOneWidget);
    expect(_enabled(tester, 'next'), isFalse);
    expect(_enabled(tester, 'previous'), isTrue);
  });
}
