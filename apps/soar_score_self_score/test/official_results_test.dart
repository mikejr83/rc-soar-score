import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/data/sample_data.dart';
import 'package:soar_score_self_score/data/sample_self_score_repository.dart';
import 'package:soar_score_self_score/data/self_score_scope.dart';
import 'package:soar_score_self_score/l10n/app_localization_delegates.dart';
import 'package:soar_score_self_score/models/group_result_row.dart';
import 'package:soar_score_self_score/models/group_results.dart';
import 'package:soar_score_self_score/models/officialization_policy.dart';
import 'package:soar_score_self_score/models/results_view.dart';
import 'package:soar_score_self_score/pages/group_results_page.dart';
import 'package:soar_score_self_score/pages/results_page.dart';
import 'package:soar_score_self_score/widgets/group_result_tile.dart';

class _Repository extends SampleSelfScoreRepository {
  const _Repository(this.preliminary, {this.review = false, this.policy});

  final bool preliminary;

  /// The contest's official-score rule the results report.
  final OfficializationPolicy? policy;

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
          GroupResultRow(
            name: row.name,
            kind: row.kind,
            time: row.time,
            score: row.score,
            zeroReason: row.zeroReason,
            reviewPending: review && i == 0,
          ),
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
      policy: policy,
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
        localizationsDelegates: appLocalizationDelegates,
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
          localizationsDelegates: appLocalizationDelegates,
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
      expect(note.data, contains('all required scores for its group'));
    },
  );

  testWidgets('a zero under review keeps its reason beside the review chip', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationDelegates,
        home: Scaffold(
          body: GroupResultTile(
            row: const GroupResultRow(
              name: 'Jane Smith',
              kind: GroupRowKind.zero,
              zeroReason: 'landed out',
              isYou: true,
              reviewPending: true,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Zero: landed out'), findsOneWidget);
    expect(find.text('Pending review'), findsOneWidget);
    expect(find.text('Time, height and landing are zeroed.'), findsOneWidget);
    expect(find.text('The review keeps the original entry.'), findsOneWidget);
  });

  testWidgets('zero, coded zero and missing score read differently', (
    tester,
  ) async {
    Future<void> pump(GroupResultRow row) => tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationDelegates,
        home: Scaffold(body: GroupResultTile(row: row)),
      ),
    );

    await pump(
      const GroupResultRow(name: 'Blake Castillo', kind: GroupRowKind.zero),
    );
    expect(find.text('Zero recorded'), findsOneWidget);
    expect(find.textContaining('null'), findsNothing);

    await pump(
      const GroupResultRow(
        name: 'Blake Castillo',
        kind: GroupRowKind.zero,
        zeroReason: 'out_of_bounds',
      ),
    );
    expect(find.text('Zero: out of bounds'), findsOneWidget);

    for (final (code, words) in [
      ('motor_restart', 'Zero: motor restart'),
      ('no_altitude_recorded', 'Zero: no altitude recorded'),
      ('overflight_gt_one_min', 'Zero: overflight over one minute'),
      ('new_server_code', 'Zero: new server code'),
    ]) {
      await pump(
        GroupResultRow(
          name: 'Blake Castillo',
          kind: GroupRowKind.zero,
          zeroReason: code,
        ),
      );
      expect(find.text(words), findsOneWidget);
    }

    await pump(
      const GroupResultRow(name: 'Blake Castillo', kind: GroupRowKind.noScore),
    );
    expect(find.text('No score yet'), findsOneWidget);

    await pump(
      const GroupResultRow(name: 'Kai Larsen', kind: GroupRowKind.retired),
    );
    expect(find.text('Retired'), findsOneWidget);
    expect(find.text('No score yet'), findsNothing);
    expect(find.text('No flight expected after retirement.'), findsOneWidget);
  });

  for (final (policy, phrase) in [
    (OfficializationPolicy.endOfRound, 'all required scores for its round'),
    (OfficializationPolicy.endOfGroup, 'all required scores for its group'),
  ]) {
    testWidgets('overall results word ${policy.name} per score', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        SelfScoreScope(
          repository: _Repository(true, policy: policy),
          child: MaterialApp(
            localizationsDelegates: appLocalizationDelegates,
            home: overall,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final note = tester.widget<Text>(
        find.byKey(const ValueKey('preliminary-note')),
      );
      expect(note.data, startsWith('These scores are preliminary'));
      expect(note.data, contains('Each score becomes official'));
      expect(note.data, contains(phrase));
    });
  }
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
