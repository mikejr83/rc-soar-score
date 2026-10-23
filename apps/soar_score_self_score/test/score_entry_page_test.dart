import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/models/landing_result.dart';
import 'package:soar_score_self_score/pages/score_entry_page.dart';
import 'package:soar_score_self_score/services/landing_search.dart';

List<LandingResult> _inchTable(int count) => [
  for (var i = 1; i <= count; i++)
    LandingResult(id: 'r$i', label: '$i"', points: 100 - i),
];

Future<void> _pump(WidgetTester tester, List<LandingResult>? table) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: table == null
          ? const ScoreEntryPage(contestId: 'c', pilotId: '12', roundId: '4')
          : ScoreEntryPage(
              contestId: 'c',
              pilotId: '12',
              roundId: '4',
              landingTable: table,
            ),
    ),
  );
}

void main() {
  test('threshold is 20 results', () {
    expect(landingUsesSheet(_inchTable(20)), true);
    expect(landingUsesSheet(_inchTable(21)), false);
  });

  test('search matches the label and a typed number', () {
    final table = _inchTable(100);
    expect(searchLandingTable(table, '99"').map((r) => r.id), ['r99']);
    expect(searchLandingTable(table, 'zzz'), isEmpty);
  });

  testWidgets('small table: sheet choice shows in the summary', (tester) async {
    await _pump(tester, null);
    await tester.enterText(find.byType(TextField).at(0), '630.4');
    await tester.enterText(find.byType(TextField).at(1), '45');

    await tester.tap(find.text('Choose landing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();

    expect(find.text('6:30.4 · 45 m · landing 50'), findsOneWidget);
  });

  testWidgets('late landing clears and disables landing', (tester) async {
    await _pump(tester, null);
    await tester.tap(find.text('Choose landing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Near'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SwitchListTile, 'Late landing'));
    await tester.pumpAndSettle();

    expect(find.text('Choose landing'), findsOneWidget);
    expect(
      find.text('Late landing is on, so landing is cleared.'),
      findsOneWidget,
    );
  });

  testWidgets('no altitude zeroes the flight and disables the fields', (
    tester,
  ) async {
    await _pump(tester, null);
    await tester.enterText(find.byType(TextField).at(0), '630');
    await tester.tap(
      find.widgetWithText(SwitchListTile, 'No altitude recorded'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Zero for the flight: no altitude recorded'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).enabled,
      false,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).enabled,
      false,
    );
    expect(find.text('Choose landing'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(SwitchListTile, 'No altitude recorded'),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).enabled,
      true,
    );
  });

  testWidgets('penalty is named only when entered', (tester) async {
    await _pump(tester, null);
    expect(find.textContaining('enalty entered'), findsNothing);
    await tester.enterText(find.byType(TextField).at(2), '50');
    await tester.pumpAndSettle();
    expect(find.textContaining('Penalty entered'), findsOneWidget);
  });

  testWidgets('large table: autocomplete selects one result', (tester) async {
    await _pump(tester, _inchTable(100));
    expect(find.text('Choose landing'), findsNothing);

    final landing = find.widgetWithText(TextField, '').last;
    await tester.enterText(find.byType(TextField).at(2), '77');
    await tester.pumpAndSettle();
    expect(find.text('77"'), findsOneWidget);
    await tester.tap(find.text('77"'));
    await tester.pumpAndSettle();

    expect(landing, findsWidgets);
    expect(find.text('23 points'), findsOneWidget);
  });

  testWidgets('large table: unmatched text says so', (tester) async {
    await _pump(tester, _inchTable(100));
    await tester.enterText(find.byType(TextField).at(2), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Not on the landing table'), findsOneWidget);
  });

  testWidgets('submit makes the form read-only', (tester) async {
    await _pump(tester, null);
    await tester.enterText(find.byType(TextField).at(0), '630');
    await tester.enterText(find.byType(TextField).at(1), '45');
    await tester.tap(find.text('Choose landing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Far'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit score'));
    await tester.pumpAndSettle();

    expect(find.text('Submit score'), findsNothing);
    expect(find.text('Submitted'), findsOneWidget);
  });
}
