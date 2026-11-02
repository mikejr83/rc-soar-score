import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/pages/contest/report_viewer_page.dart';
import 'package:soar_score_contest/services/reports/report_kind.dart';
import 'package:soar_score_contest/services/reports/viewer/page_setup.dart';
import 'package:soar_score_contest/services/reports/viewer/report_print_result.dart';
import 'package:soar_score_contest/services/reports/viewer/report_view_params.dart';
import 'package:soar_score_contest/widgets/reports/scoring_sheet/scoring_sheet_table_view.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/matrix_test_support.dart';
import '../support/next_step_widget_support.dart';
import '../support/workspace_facts_support.dart';

Future<void> _pump(
  WidgetTester tester, {
  bool lanes = true,
  ReportViewParams params = const ReportViewParams(),
  ContestScores Function(CurrentMatrix matrix)? scores,
}) async {
  final matrix = drawnMatrix(lanes: lanes);
  final server = WorkspaceServer(
    configuration: matrixConfiguration(),
    matrix: matrix,
    scores: scores?.call(matrix) ?? scoresFor(matrix, const {}),
  );
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ApiClientInherited(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient(
          (request) async => request.url.path.endsWith('/landing-tables')
              ? http.Response(
                  '{"landing_tables": []}',
                  200,
                  headers: {'content-type': 'application/json'},
                )
              : server.handle(request),
        ),
      ),
      child: MaterialApp(
        locale: const Locale('en', 'US'),
        home: ReportViewerPage(
          printer: const NotWiredReportPrinter(),
          contestId: matrixContestId,
          report: ReportKind.sheet,
          params: params,
          pollInterval: null,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String field, String option) async {
  await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, field));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

/// Text on the sheet's tables only, rich text included; the panel's own
/// controls also say "Round 1".
Finder _sheet(String text) => find.descendant(
  of: find.byType(ScoringSheetTableView),
  matching: find.textContaining(text, findRichText: true),
);

/// Round 1: the first drawn pilot has an official 9:57 with a 119 m launch and
/// a 100 point penalty; the second has one pending submission.
ContestScores _scored(CurrentMatrix matrix) {
  final first = matrix.assignments.where((a) {
    final round = matrix.rounds.firstWhere((r) => r.id == a.scheduledRoundId);
    return round.ordinal == 1;
  }).toList();
  ScoreSlot slot(
    MatrixAssignment a,
    ScorePlaceholderState state,
    Map<String, Object?> components,
  ) {
    final placeholder = ScorePlaceholder(
      id: Id.create(),
      contestId: a.contestId,
      contestParticipationId: a.contestParticipationId,
      assignmentId: a.id,
      state: state,
      scoreRevision: 1,
    );
    return ScoreSlot(
      placeholder: placeholder,
      officialScore: OfficialScore(
        id: Id.create(),
        contestId: a.contestId,
        scorePlaceholderId: placeholder.id,
        scoreAttemptId: Id.create(),
        scoreRevision: 1,
        components: components,
        setAt: DateTime.utc(2026, 10, 17, 15),
        setBy: Id.create(),
        reason: 'Entered by the director',
      ),
    );
  }

  return ContestScores(
    rounds: [
      for (final round in matrix.rounds)
        RoundProgress(
          roundId: round.id,
          ordinal: round.ordinal,
          scored: round.ordinal == 1 ? 2 : 0,
          total: 4,
        ),
    ],
    slots: [
      slot(first[0], ScorePlaceholderState.official, const {
        'time_flown': 597,
        'launch_height': 119,
        'flight_penalty': 100,
        'out_of_bounds': true,
      }),
      slot(first[1], ScorePlaceholderState.submitted, const {
        'time_flown': 540,
        'launch_height': 80,
      }),
      for (final a in matrix.assignments.skip(2)) scoreSlot(a),
    ],
  );
}

void main() {
  testWidgets('shows the draw by round and group with blank score cells', (
    tester,
  ) async {
    await _pump(tester);

    expect(
      find.text('Official Scoring - ${matrixContest().name}'),
      findsOneWidget,
    );
    for (final head in ['Lane', 'Pilot', 'Time', 'Landing', 'Penalty']) {
      expect(find.text(head), findsWidgets, reason: head);
    }
    expect(find.text('Reflight'), findsWidgets);
    expect(find.text('Validated'), findsWidgets);
    expect(_sheet('Round 1'), findsOneWidget);
    expect(_sheet('Round 2'), findsOneWidget);
    expect(_sheet('Group A · 2 Pilots'), findsNWidgets(2));
    expect(_sheet('Group B · 2 Pilots'), findsNWidgets(2));
    // The working time is on the rounds, not the groups.
    expect(_sheet('Round 1 · Working Time'), findsOneWidget);
    expect(_sheet('Pilots · Working Time'), findsNothing);
    // Round 1 group A: Bo on lane 1, Ann on lane 2.
    final bo = tester.getTopLeft(find.text('Ray, Bo').first).dy;
    final ann = tester.getTopLeft(find.text('Lee, Ann').first).dy;
    expect(bo, lessThan(ann));
    // The sheet is a form: nothing prints in the score cells.
    expect(find.text('9:57'), findsNothing);
    expect(find.textContaining('Includes scores'), findsNothing);
  });

  testWidgets('a contest without lanes has no Lane column', (tester) async {
    await _pump(tester, lanes: false);
    expect(find.text('Lane'), findsNothing);
    expect(find.text('Pilot'), findsWidgets);
  });

  testWidgets('the round range limits the sheet and lives in the URL', (
    tester,
  ) async {
    await _pump(tester);

    await _choose(tester, 'To round', 'Round 1');
    expect(_sheet('Round 1'), findsOneWidget);
    expect(_sheet('Round 2'), findsNothing);
    expect(find.textContaining('Showing rounds 1 to 1 of 2.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sheet-show-all')));
    await tester.pumpAndSettle();
    expect(_sheet('Round 2'), findsOneWidget);
    expect(find.byKey(const ValueKey('sheet-show-all')), findsNothing);
  });

  testWidgets('From after To keeps the sheet and says so', (tester) async {
    await _pump(tester);

    await _choose(tester, 'From round', 'Round 2');
    await _choose(tester, 'To round', 'Round 1');
    expect(find.textContaining('From round must be on or before'), findsOne);
    expect(
      find.text('Official Scoring - ${matrixContest().name}'),
      findsOneWidget,
    );
  });

  testWidgets('a range of undrawn rounds explains itself, not a blank sheet', (
    tester,
  ) async {
    await _pump(
      tester,
      params: const ReportViewParams(filters: {'from': '5', 'to': '6'}),
    );
    expect(find.text('No drawn rounds in this range'), findsOneWidget);
  });

  testWidgets('Validated and Club follow their switches', (tester) async {
    await _pump(tester);
    expect(_sheet('Club'), findsNothing);
    expect(find.text('Validated'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('sheet-club')));
    await tester.pumpAndSettle();
    expect(_sheet('Club'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sheet-validated')));
    await tester.pumpAndSettle();
    expect(_sheet('Validated'), findsNothing);
  });

  testWidgets('the panel reports the writing width and pages', (tester) async {
    await _pump(tester);
    expect(find.byKey(const ValueKey('sheet-readout')), findsOneWidget);
    expect(find.textContaining('Writing cells'), findsOneWidget);
  });

  group('orientation', () {
    testWidgets('is Portrait when the columns fit across it', (tester) async {
      await _pump(tester);
      expect(find.textContaining('Letter · Portrait'), findsWidgets);
    });

    testWidgets('keeps the director’s choice', (tester) async {
      await _pump(
        tester,
        params: const ReportViewParams(orientation: PageOrientation.landscape),
      );
      expect(find.textContaining('Letter · Landscape'), findsWidgets);
    });
  });

  group('pre-fill', () {
    testWidgets('is off, with its reason, until a score exists', (
      tester,
    ) async {
      await _pump(tester);
      final pre = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Pre-fill'),
      );
      expect(pre.onChanged, isNull);
      expect(find.text('No scores have been entered yet.'), findsOneWidget);
    });

    testWidgets('prints the scores entered and marks the unofficial', (
      tester,
    ) async {
      await _pump(
        tester,
        scores: _scored,
        params: const ReportViewParams(filters: {'pre': '1'}),
      );

      expect(find.text('9:57'), findsOneWidget);
      expect(find.text('9:00*'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(
        find.textContaining('Includes scores through round 1 · * not official'),
        findsOneWidget,
      );
    });

    testWidgets('prints nothing extra while it is off', (tester) async {
      await _pump(tester, scores: _scored);
      final pre = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Pre-fill'),
      );
      expect(pre.onChanged, isNotNull);
      expect(pre.value, isFalse);
      expect(find.text('9:57'), findsNothing);
      expect(find.textContaining('Includes scores'), findsNothing);
    });
  });
}
