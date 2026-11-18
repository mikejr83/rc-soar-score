import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/data/sample_data.dart';
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/l10n/app_localizations.dart';
import 'package:soar_score_self_score/models/group_results.dart';
import 'package:soar_score_self_score/models/results_view.dart';
import 'package:soar_score_self_score/pages/group_results_page.dart';
import 'package:soar_score_self_score/pages/results_page.dart';

class _Repository extends SampleSelfScoreRepository {
  const _Repository(this.preliminary);

  final bool preliminary;

  @override
  Future<GroupResults> groupResults(
    String contestId,
    String pilotId,
    int round,
  ) async {
    final data = await super.groupResults(contestId, pilotId, round);
    return GroupResults(
      contestName: data.contestName,
      round: data.round,
      group: data.group,
      latestRound: data.latestRound,
      rows: data.rows,
      preliminary: preliminary,
    );
  }

  @override
  Future<ResultsView> results(String contestId, {int? asOfRound}) async {
    final data = await super.results(contestId, asOfRound: asOfRound);
    return ResultsView(
      contestName: data.contestName,
      latestRound: data.latestRound,
      snapshot: data.snapshot,
      heldRound: data.heldRound,
      preliminary: preliminary,
    );
  }
}

Future<void> _pump(WidgetTester tester, bool preliminary, Widget page) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    SelfScoreScope(
      repository: _Repository(preliminary),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const group = GroupResultsPage(
    contestId: SampleData.contestId,
    pilotId: '12',
    roundId: '4',
  );
  const overall = ResultsPage(contestId: SampleData.contestId);
  for (final (name, page) in [('group', group), ('overall', overall)]) {
    testWidgets(
      '$name results show Preliminary while scores are not official',
      (tester) async {
        await _pump(tester, true, page);
        expect(find.text('Preliminary'), findsOneWidget);
        expect(find.byKey(const ValueKey('preliminary-note')), findsOneWidget);
      },
    );
    testWidgets('$name results drop Preliminary once all are official', (
      tester,
    ) async {
      await _pump(tester, false, page);
      expect(find.text('Preliminary'), findsNothing);
      expect(find.byKey(const ValueKey('preliminary-note')), findsNothing);
    });
  }
}
