import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/matrix_test_support.dart';

MatrixServer _server({
  bool lanes = false,
  bool teams = true,
  bool numbers = true,
  Map<String, Object?>? drawn,
}) => MatrixServer(
  configuration: matrixConfiguration({
    if (lanes) 'lane_mode': 'Random',
    if (numbers) 'participant_numbers_enabled': true,
    if (teams) ...{'teams_enabled': true, 'team_pilot_count': 2},
  }),
  matrix: drawnMatrix(lanes: lanes, config: drawn),
);

final _panel = find.byKey(const ValueKey('pilot-panel'));

Finder _row(int pilot, int round) =>
    find.bySemanticsLabel(RegExp('Pilot $pilot, .*round $round'));

void main() {
  testWidgets('shows rounds, groups, and that each pilot flies once', (
    tester,
  ) async {
    await pumpMatrixPage(tester, _server());
    expect(find.text('Round 1'), findsOneWidget);
    expect(find.text('Round 2'), findsOneWidget);
    expect(find.text('Group A'), findsOneWidget);
    expect(find.text('Group B'), findsOneWidget);
    expect(find.text('4 pilots, each once'), findsNWidgets(2));
    expect(find.text('Not flown'), findsNWidgets(2));
    expect(find.text('Ann Lee'), findsNWidgets(2));
    expect(find.text('Draw the first matrix'), findsNothing);
    expect(find.text('Tim Keeper'), findsNothing);
  });

  testWidgets('the fairness summary explains the score', (tester) async {
    await pumpMatrixPage(tester, _server());
    expect(find.text('92%'), findsOneWidget);
    expect(find.text('Good draw'), findsOneWidget);
    expect(
      find.text('0% is a random draw, 100% is the best possible.'),
      findsOneWidget,
    );
    expect(find.text('Unmet opponents'), findsOneWidget);
    expect(find.text('Never'), findsOneWidget);
    expect(find.text('Pilot pairs by number of meetings'), findsOneWidget);
    expect(find.text('Mean absolute deviation 0.44'), findsOneWidget);
  });

  testWidgets('draw details are collapsed until asked for', (tester) async {
    await pumpMatrixPage(tester, _server());
    expect(find.text('1849302217'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('draw-details-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('1849302217'), findsOneWidget);
    expect(find.text('optimized-1'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
  });

  testWidgets('hiding the summary leaves one line', (tester) async {
    await pumpMatrixPage(tester, _server());
    await tester.tap(find.byKey(const ValueKey('summary-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Fairness 92%'), findsOneWidget);
    expect(find.textContaining('2 unmet pairs'), findsOneWidget);
    expect(find.text('Pilot pairs by number of meetings'), findsNothing);
  });

  testWidgets('no lanes are shown when the lane mode is None', (tester) async {
    await pumpMatrixPage(tester, _server());
    expect(find.text('L1'), findsNothing);
  });

  testWidgets('lanes show when the lane mode is Random', (tester) async {
    await pumpMatrixPage(tester, _server(lanes: true));
    expect(find.text('L1'), findsWidgets);
  });

  testWidgets('shows no team markers or filter when teams are not enabled', (
    tester,
  ) async {
    await pumpMatrixPage(tester, _server(teams: false));
    expect(find.text('Ann Lee'), findsNWidgets(2));
    expect(find.text('FG'), findsNothing);
    expect(find.byKey(const ValueKey('team-filter')), findsNothing);
    await tester.tap(_row(1, 1));
    await tester.pumpAndSettle();
    expect(find.text('No. 1'), findsOneWidget);
    expect(find.textContaining('Flying Gators'), findsNothing);
  });

  testWidgets('shows no pilot numbers when the option is off', (tester) async {
    await pumpMatrixPage(tester, _server(numbers: false));
    expect(find.text('Ann Lee'), findsNWidgets(2));
    expect(find.bySemanticsLabel(RegExp('Pilot 1,')), findsNothing);
    expect(find.text('Find pilot by name'), findsOneWidget);
    expect(find.text('Find pilot by name or number'), findsNothing);
    await tester.tap(find.bySemanticsLabel(RegExp('Ann Lee, .*round 1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('No. '), findsNothing);
    expect(find.text('Flying Gators'), findsWidgets);
  });

  testWidgets('the grid is as tall as its rows', (tester) async {
    await pumpMatrixPage(tester, _server(), size: const Size(1280, 1400));
    final grid = tester.getRect(find.byKey(const ValueKey('grid-scroll')));
    expect(grid.height, lessThan(300));
  });

  group('pilot highlight', () {
    testWidgets(
      'selecting a pilot highlights every round and opens the panel',
      (tester) async {
        await pumpMatrixPage(tester, _server());
        expect(_panel, findsNothing);
        await tester.tap(_row(1, 1));
        await tester.pumpAndSettle();
        expect(_panel, findsOneWidget);
        // One marker in each round plus the panel header.
        expect(find.byIcon(Icons.person_pin), findsNWidgets(3));
        expect(find.text('Opponents (2 of 3)'), findsOneWidget);
        expect(find.text('Never meets (1)'), findsOneWidget);
        expect(find.text('Pilots in no group with Ann.'), findsOneWidget);
        expect(find.text('No. 1 · Flying Gators'), findsOneWidget);
        expect(find.text('R1 · A'), findsOneWidget);
        expect(find.text('R2 · A'), findsOneWidget);
      },
    );

    testWidgets('selecting again, or Esc, clears it', (tester) async {
      await pumpMatrixPage(tester, _server());
      await tester.tap(_row(1, 1));
      await tester.pumpAndSettle();
      await tester.tap(_row(1, 2));
      await tester.pumpAndSettle();
      expect(_panel, findsNothing);

      await tester.tap(_row(2, 1));
      await tester.pumpAndSettle();
      expect(_panel, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_panel, findsNothing);
    });

    testWidgets('choosing another pilot switches the highlight', (
      tester,
    ) async {
      await pumpMatrixPage(tester, _server());
      await tester.tap(_row(1, 1));
      await tester.pumpAndSettle();
      await tester.tap(_row(3, 1));
      await tester.pumpAndSettle();
      expect(find.text('No. 3 · Flying Gators'), findsOneWidget);
    });

    testWidgets('the close button clears it', (tester) async {
      await pumpMatrixPage(tester, _server());
      await tester.tap(_row(1, 1));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('clear-highlight')));
      await tester.pumpAndSettle();
      expect(_panel, findsNothing);
    });

    testWidgets('a narrow screen docks the panel under the grid', (
      tester,
    ) async {
      await pumpMatrixPage(tester, _server(), size: const Size(800, 1000));
      await tester.tap(_row(1, 1));
      await tester.pumpAndSettle();
      final panel = tester.getRect(_panel);
      expect(panel.width, 800 - 32, reason: 'a bottom sheet spans the page');
      expect(panel.height, 380);
    });
  });

  group('find and filter', () {
    testWidgets('search highlights matches and says how many', (tester) async {
      await pumpMatrixPage(tester, _server());
      await tester.enterText(find.byKey(const ValueKey('find-pilot')), 'lee');
      await tester.pumpAndSettle();
      expect(find.text('1 pilot matches'), findsOneWidget);
      expect(find.byKey(const ValueKey('jump-to-first')), findsOneWidget);
    });

    testWidgets('a number finds the pilot', (tester) async {
      await pumpMatrixPage(tester, _server());
      await tester.enterText(find.byKey(const ValueKey('find-pilot')), '3');
      await tester.pumpAndSettle();
      expect(find.text('1 pilot matches'), findsOneWidget);
    });

    testWidgets('no match is said plainly', (tester) async {
      await pumpMatrixPage(tester, _server());
      await tester.enterText(find.byKey(const ValueKey('find-pilot')), 'zed');
      await tester.pumpAndSettle();
      expect(find.text('No pilot matches “zed”'), findsOneWidget);
      expect(find.byKey(const ValueKey('jump-to-first')), findsNothing);
    });

    testWidgets('a team filter shows one team and counts the hidden', (
      tester,
    ) async {
      await pumpMatrixPage(tester, _server());
      await tester.tap(find.byKey(const ValueKey('team-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('team-FG')));
      await tester.pumpAndSettle();
      expect(find.text('Team: Flying Gators'), findsOneWidget);
      expect(find.text('Bo Ray'), findsNothing);
      expect(find.text('Ann Lee'), findsNWidgets(2));
      expect(find.text('1 hidden by the team filter'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('clear-team')));
      await tester.pumpAndSettle();
      expect(find.text('Bo Ray'), findsNWidgets(2));
    });
  });

  group('configuration changed banner', () {
    testWidgets('names what differs and says the matrix is unchanged', (
      tester,
    ) async {
      await pumpMatrixPage(
        tester,
        _server(drawn: const {'team_protection': true, 'lane_mode': 'None'}),
      );
      expect(
        find.text('Configuration changed since this draw'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Team protection is now Off (drawn with On).'),
        findsOneWidget,
      );
      expect(find.textContaining('The matrix is unchanged.'), findsOneWidget);
    });

    testWidgets('is absent when nothing differs', (tester) async {
      await pumpMatrixPage(
        tester,
        _server(drawn: const {'team_protection': false, 'lane_mode': 'None'}),
      );
      expect(find.text('Configuration changed since this draw'), findsNothing);
    });
  });

  group('shared states', () {
    testWidgets('an unreachable server shows Matrix unavailable', (
      tester,
    ) async {
      await pumpMatrixPage(tester, MatrixServer(offline: true));
      expect(find.text('Matrix unavailable'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
