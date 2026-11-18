import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/data/sample_data.dart';
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/l10n/app_localizations.dart';
import 'package:soar_score_self_score/models/group_result_row.dart';
import 'package:soar_score_self_score/models/group_results.dart';
import 'package:soar_score_self_score/models/officialization_policy.dart';
import 'package:soar_score_self_score/models/results_view.dart';
import 'package:soar_score_self_score/pages/group_results_page.dart';
import 'package:soar_score_self_score/pages/results_page.dart';

class _Repository extends SampleSelfScoreRepository {
  const _Repository(this.preliminary, {this.review = false});

  final bool preliminary;

  /// Marks the first row as held by an open review.
  final bool review;

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
      rows: [
        for (final (i, row) in data.rows.indexed)
          if (row.kind == GroupRowKind.pendingReview && !review)
            GroupResultRow(
              name: row.name,
              kind: GroupRowKind.scored,
              time: row.time,
              score: row.score,
            )
          else if (review && i == 0)
            GroupResultRow(
              name: row.name,
              kind: GroupRowKind.pendingReview,
              time: row.time,
              score: row.score,
            )
          else
            row,
      ],
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

Future<void> _pump(
  WidgetTester tester,
  bool preliminary,
  Widget page, {
  bool review = false,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    SelfScoreScope(
      repository: _Repository(preliminary, review: review),
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

  testWidgets('a row held by a review adds the hold to the group note', (
    tester,
  ) async {
    await _pump(tester, true, group, review: true);
    expect(find.textContaining('A score under review is held'), findsOneWidget);
    await _pump(tester, true, group);
    expect(find.textContaining('A score under review is held'), findsNothing);
  });

  testWidgets(
    'an official viewer beside a preliminary peer sees the page note',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: SelfScoreScope(
            repository: const _MixedRepository(),
            child: const GroupResultsPage(
              contestId: SampleData.contestId,
              pilotId: '12',
              roundId: '4',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The viewer's own row is scored, a peer has nothing yet.
      expect(find.text('(you)'), findsOneWidget);
      expect(find.text('No score yet'), findsOneWidget);
      expect(find.text('Preliminary'), findsOneWidget);
      final note = tester.widget<Text>(
        find.byKey(const ValueKey('preliminary-note'), skipOffstage: false),
      );
      expect(note.data, startsWith('These scores are preliminary'));
      expect(note.data, contains('in the group'));
    },
  );
}

class _MixedRepository extends SampleSelfScoreRepository {
  const _MixedRepository();

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
      policy: OfficializationPolicy.endOfGroup,
      rows: const [
        GroupResultRow(
          name: 'Jane Smith',
          kind: GroupRowKind.scored,
          time: '9:00',
          score: '962.5',
          isYou: true,
        ),
        GroupResultRow(name: 'Sam Chen', kind: GroupRowKind.noScore),
      ],
    );
  }
}
