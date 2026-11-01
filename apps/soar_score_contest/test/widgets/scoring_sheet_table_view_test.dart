import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/report_pilot.dart';
import 'package:soar_score_contest/services/reports/scoring_sheet/scoring_sheet_columns.dart';
import 'package:soar_score_contest/services/reports/scoring_sheet/scoring_sheet_data.dart';
import 'package:soar_score_contest/services/reports/scoring_sheet/scoring_sheet_layout.dart';
import 'package:soar_score_contest/widgets/reports/scoring_sheet/scoring_sheet_table_view.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/scoring_sheet_support.dart';

Future<void> _pump(WidgetTester tester, ReportPilot pilot) async {
  final strips = ScoringSheetColumns.plan(
    ScoringSheetColumns.forContest(
      discipline: 'F5J',
      lanes: true,
      restart: true,
      options: sheetOptions(),
    ),
    letterLandscapeBody.width,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ScoringSheetTableView(
            page: ScoringSheetPage(
              items: [
                ScoringSheetPilotRow(ScoringSheetPilot(pilot: pilot, lane: 1)),
              ],
              strip: strips.single,
              band: 1,
              stripIndex: 0,
            ),
            workingTime: '10:00',
            label: 'Page 1',
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a very long name stays whole inside its cell', (tester) async {
    tester.view.physicalSize = const Size(1280, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final pilot = ReportPilot(
      participationId: Id.create(),
      firstName: 'Maximiliano Alexander Bartholomew',
      lastName: 'Vanderhoeven-Montgomery-Featherstonehaugh',
      number: 7,
    );
    await _pump(tester, pilot);

    final name = find.text(pilot.listName);
    expect(name, findsOneWidget);
    final cell = tester.getRect(
      find.ancestor(of: name, matching: find.byType(Container)).first,
    );
    final text = tester.getRect(name);
    // Drawn smaller if it has to be, never cut off or spilling out.
    expect(text.height, lessThanOrEqualTo(ScoringSheetStyle.rowHeight));
    expect(text.width, lessThanOrEqualTo(cell.width));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a short name is not shrunk', (tester) async {
    tester.view.physicalSize = const Size(1280, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final pilot = ReportPilot(
      participationId: Id.create(),
      firstName: 'Bo',
      lastName: 'Ray',
    );
    await _pump(tester, pilot);

    final text = tester.getRect(find.text('Ray, Bo'));
    expect(text.height, closeTo(15, 1));
  });
}
