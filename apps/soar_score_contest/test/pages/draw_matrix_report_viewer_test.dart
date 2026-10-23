import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/pages/contest/report_viewer_page.dart';
import 'package:soar_score_contest/widgets/reports/draw_matrix/draw_matrix_table_view.dart';
import 'package:soar_score_contest/services/reports/report_kind.dart';
import 'package:soar_score_contest/services/reports/viewer/report_print_result.dart';
import 'package:soar_score_contest/services/reports/viewer/report_view_params.dart';

import '../support/matrix_test_support.dart';
import '../support/next_step_widget_support.dart';
import '../support/workspace_facts_support.dart';

Future<void> _pump(
  WidgetTester tester, {
  bool lanes = true,
  ReportViewParams params = const ReportViewParams(),
}) async {
  final matrix = drawnMatrix(lanes: lanes);
  final server = WorkspaceServer(
    configuration: matrixConfiguration(),
    matrix: matrix,
    scores: scoresFor(matrix, const {}),
  );
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ApiClientInherited(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient(server.handle),
      ),
      child: MaterialApp(
        locale: const Locale('en', 'US'),
        home: ReportViewerPage(
          printer: const NotWiredReportPrinter(),
          contestId: matrixContestId,
          report: ReportKind.matrix,
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

Finder _text(String text) => find.text(text);

/// Text on the sheet's tables only, rich text included; the panel's own
/// controls also say "Round 1".
Finder _sheet(String text) => find.descendant(
  of: find.byType(DrawMatrixTableView),
  matching: find.textContaining(text, findRichText: true),
);

void main() {
  testWidgets('shows each round and group with its pilots in lane order', (
    tester,
  ) async {
    await _pump(tester);

    expect(_text('Flight Matrix - ${matrixContest().name}'), findsOneWidget);
    for (final head in ['Lane', 'Pilot']) {
      expect(_text(head), findsOneWidget, reason: head);
    }
    expect(_sheet('Round 1'), findsOneWidget);
    expect(_sheet('Round 2'), findsOneWidget);
    expect(_sheet('Group A · 2 pilots'), findsNWidgets(2));
    expect(_sheet('Group B · 2 pilots'), findsNWidgets(2));
    // Round 1 group A: Bo on lane 1, Ann on lane 2.
    final bo = tester.getTopLeft(_text('Ray, Bo').first).dy;
    final ann = tester.getTopLeft(_text('Lee, Ann').first).dy;
    expect(bo, lessThan(ann));
  });

  testWidgets('a contest without lanes has no Lane column', (tester) async {
    await _pump(tester, lanes: false);
    expect(_text('Lane'), findsNothing);
    expect(_text('Pilot'), findsOneWidget);
  });

  testWidgets('the round range limits the sheet', (tester) async {
    await _pump(tester);

    await _choose(tester, 'To round', 'Round 1');
    expect(_sheet('Round 1'), findsOneWidget);
    expect(_sheet('Round 2'), findsNothing);
    expect(find.textContaining('Showing rounds 1 to 1 of 2.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('matrix-show-all')));
    await tester.pumpAndSettle();
    expect(_sheet('Round 2'), findsOneWidget);
    expect(find.byKey(const ValueKey('matrix-show-all')), findsNothing);
  });

  testWidgets('From after To keeps the sheet and says so', (tester) async {
    await _pump(tester);

    await _choose(tester, 'From round', 'Round 2');
    await _choose(tester, 'To round', 'Round 1');
    expect(find.textContaining('From round must be on or before'), findsOne);
    expect(_text('Flight Matrix - ${matrixContest().name}'), findsOneWidget);
  });

  testWidgets('compact mode disables additional pilot info with its reason', (
    tester,
  ) async {
    await _pump(tester, params: const ReportViewParams(filters: {'inf': '1'}));

    SwitchListTile additional() => tester.widget(
      find.widgetWithText(SwitchListTile, 'Additional pilot info'),
    );
    expect(additional().onChanged, isNotNull);
    expect(_text('Club'), findsWidgets);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Compact mode'));
    await tester.pumpAndSettle();

    expect(additional().onChanged, isNull);
    expect(_text('Not available in compact mode'), findsOneWidget);
    expect(
      find.text('Kept as set. They apply again when Compact mode is off.'),
      findsOneWidget,
    );
    // The choice is kept, but its columns are not drawn.
    expect(additional().value, isTrue);
    expect(find.widgetWithText(CheckboxListTile, 'Club'), findsOneWidget);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.widgetWithText(CheckboxListTile, 'Club'),
          )
          .onChanged,
      isNull,
    );
  });

  testWidgets('a range of undrawn rounds explains itself, not a blank sheet', (
    tester,
  ) async {
    await _pump(
      tester,
      params: const ReportViewParams(filters: {'from': '5', 'to': '6'}),
    );
    expect(_text('No drawn rounds in this range'), findsOneWidget);
    expect(
      find.textContaining('Only rounds 1 to 2 can be printed'),
      findsWidgets,
    );
  });
}
