import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'package:soar_score_contest/widgets/scoring/score_landing_chips.dart';

import '../support/matrix_test_support.dart';
import '../support/scoring_test_support.dart';

Finder _time(int round, int pilot) => find.byKey(
  ValueKey('score-time-${scoringAssignmentId(round, pilot).value}'),
);
Finder _height(int round, int pilot) => find.byKey(
  ValueKey('score-height-${scoringAssignmentId(round, pilot).value}'),
);
Finder _save(int round, int pilot) => find.byKey(
  ValueKey('score-save-${scoringAssignmentId(round, pilot).value}'),
);
Finder _row(int round, int pilot) => find.byKey(
  ValueKey('score-row-${scoringAssignmentId(round, pilot).value}'),
);

Future<void> _activate(WidgetTester tester, int round, int pilot) async {
  await tester.tap(_row(round, pilot));
  await tester.pumpAndSettle();
}

void main() {
  for (final (name, size) in [
    ('medium', const Size(700, 1400)),
    ('compact', const Size(400, 1400)),
  ]) {
    testWidgets('lays out at $name width without overflow', (tester) async {
      await pumpScoringPage(
        tester,
        ScoringServer(),
        size: size,
        round: 1,
        group: 1,
      );
      await tester.tap(_row(1, 1));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('score-grid-header')), findsNothing);
      expect(find.text('Ann Lee'), findsOneWidget);
      expect(find.text('Time flown (m:ss)'), findsWidgets);
    });
  }

  testWidgets('wide width shows one heading over the columns', (tester) async {
    await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
    expect(find.byKey(const ValueKey('score-grid-header')), findsOneWidget);
    expect(find.text('Landing · flags'), findsOneWidget);
    expect(find.text('Indicators'), findsOneWidget);
    // The heading and the rows share their column positions.
    final head = tester.getTopLeft(find.text('Time flown'));
    final field = tester.getTopLeft(_time(1, 1));
    expect(field.dx, closeTo(head.dx, 12));
  });

  testWidgets('opens the first group that is not scored', (tester) async {
    final server = ScoringServer();
    server.seedScore(scoringAssignmentId(1, 1), {
      'time_flown': 540,
      'launch_height': 180,
    });
    server.seedScore(scoringAssignmentId(1, 2), {
      'time_flown': 500,
      'launch_height': 170,
    });
    await pumpScoringPage(tester, server);
    expect(find.text('Round 1 of 2'), findsOneWidget);
    expect(find.textContaining('Group B of 2'), findsOneWidget);
    expect(find.text('Cy Fox'), findsOneWidget);
    expect(find.text('Ann Lee'), findsNothing);
  });

  testWidgets('honours the round and group of the route', (tester) async {
    await pumpScoringPage(tester, ScoringServer(), round: 2, group: 2);
    expect(find.text('Round 2 of 2'), findsOneWidget);
    expect(find.textContaining('Group B of 2'), findsOneWidget);
    expect(find.text('Bo Ray'), findsOneWidget);
    expect(find.text('Di Park'), findsOneWidget);
  });

  testWidgets('the time field shows what it parsed and rejects 6:75', (
    tester,
  ) async {
    await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
    await _activate(tester, 1, 1);
    await tester.enterText(_time(1, 1), '630.4');
    await tester.pump();
    expect(find.text('6:30.4'), findsOneWidget);
    await tester.enterText(_time(1, 1), '675');
    await tester.pump();
    expect(find.byKey(const ValueKey('score-time-error')), findsOneWidget);
    expect(find.textContaining('Seconds can’t be above 59'), findsOneWidget);
    expect(find.text('Out of range'), findsOneWidget);
    // The rejected input is kept.
    expect(tester.widget<TextField>(_time(1, 1)).controller!.text, '675');
  });

  testWidgets('a time at the working time is rejected', (tester) async {
    await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
    await _activate(tester, 1, 1);
    await tester.enterText(_time(1, 1), '1000');
    await tester.pump();
    expect(find.text('Out of range'), findsOneWidget);
    expect(find.byKey(const ValueKey('score-time-error')), findsOneWidget);
    expect(
      find.textContaining(
        'The longest possible time is 9:59 with a 10:00 working time. '
        '1000 reads as 10:00.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('saves one row with the typed components', (tester) async {
    final server = ScoringServer();
    await pumpScoringPage(tester, server, round: 1, group: 1);
    await _activate(tester, 1, 1);
    await tester.enterText(_time(1, 1), '630');
    await tester.enterText(_height(1, 1), '180');
    await tester.pump();
    expect(find.text('1 unsaved row'), findsOneWidget);
    await tester.tap(
      find.byKey(
        ValueKey('score-landing-${scoringAssignmentId(1, 1).value}-within_1m'),
      ),
    );
    await tester.pump();
    await tester.tap(_save(1, 1));
    await tester.pumpAndSettle();
    expect(server.entries, hasLength(1));
    final body = server.entries.single;
    expect(body['base_score_revision'], 0);
    expect(body['components'], {
      'time_flown': 390,
      'launch_height': 180,
      'landing': 'within_1m',
    });
    // The next pilot's row is open for entry.
    expect(find.text('Official'), findsOneWidget);
  });

  testWidgets('late landing clears and disables the landing', (tester) async {
    await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
    await _activate(tester, 1, 1);
    final id = scoringAssignmentId(1, 1).value;
    await tester.tap(find.byKey(ValueKey('score-landing-$id-within_1m')));
    await tester.pump();
    await tester.tap(find.byKey(ValueKey('score-late-$id')));
    await tester.pump();
    expect(
      find.text('Late landing: the landing bonus is not given'),
      findsOneWidget,
    );
    final chip = tester.widget<ScoreLandingChip>(
      find.byKey(ValueKey('score-landing-$id-within_1m')),
    );
    expect(chip.selected, isFalse);
    expect(chip.enabled, isFalse);
  });

  testWidgets('out of bounds zeroes time and height and says why', (
    tester,
  ) async {
    await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
    await _activate(tester, 1, 1);
    await tester.enterText(_time(1, 1), '630');
    await tester.enterText(_height(1, 1), '180');
    final id = scoringAssignmentId(1, 1).value;
    await tester.tap(find.byKey(ValueKey('score-oob-$id')));
    await tester.pump();
    expect(find.text('Scores 0'), findsWidgets);
    expect(tester.widget<TextField>(_time(1, 1)).enabled, isFalse);
    expect(tester.widget<TextField>(_time(1, 1)).controller!.text, isEmpty);
    // Motor restart cannot be turned on at the same time.
    expect(find.text('Off while out of bounds is on'), findsWidgets);
  });

  testWidgets('motor restart is hidden when the contest does not allow it', (
    tester,
  ) async {
    await pumpScoringPage(
      tester,
      ScoringServer(discipline: {'motor_restart_mode': 'not_allowed'}),
      round: 1,
      group: 1,
    );
    await _activate(tester, 1, 1);
    expect(find.text('Motor restart'), findsNothing);
    expect(find.text('Out of bounds'), findsOneWidget);
  });

  testWidgets('a zero must be confirmed on the row before it saves', (
    tester,
  ) async {
    final server = ScoringServer();
    await pumpScoringPage(tester, server, round: 1, group: 1);
    await _activate(tester, 1, 1);
    final id = scoringAssignmentId(1, 1).value;
    await tester.tap(find.byKey(ValueKey('score-oob-$id')));
    await tester.pump();
    expect(find.text('Saving scores 0 for this pilot.'), findsOneWidget);
    expect(tester.widget<FilledButton>(_save(1, 1)).onPressed, isNull);
    await tester.tap(find.byKey(ValueKey('score-confirm-zero-$id')));
    await tester.pump();
    await tester.tap(_save(1, 1));
    await tester.pumpAndSettle();
    expect(server.entries.single['components'], {'out_of_bounds': true});
  });

  testWidgets('a failed save keeps the values and offers Retry', (
    tester,
  ) async {
    final server = ScoringServer()..offlineOnEntry = true;
    await pumpScoringPage(tester, server, round: 1, group: 1);
    await _activate(tester, 1, 1);
    await tester.enterText(_time(1, 1), '630');
    await tester.enterText(_height(1, 1), '180');
    await tester.pump();
    await tester.tap(_save(1, 1));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('score-save-failed')), findsOneWidget);
    expect(find.byKey(const ValueKey('score-retry')), findsOneWidget);
    expect(tester.widget<TextField>(_time(1, 1)).controller!.text, '6:30');

    server.offlineOnEntry = false;
    await tester.tap(find.byKey(const ValueKey('score-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('score-save-failed')), findsNothing);
    expect(server.entries, hasLength(1));
  });

  testWidgets(
    'a stale revision shows both values and lets the director choose',
    (tester) async {
      final server = ScoringServer();
      await pumpScoringPage(tester, server, round: 1, group: 1);
      await _activate(tester, 1, 1);
      await tester.enterText(_time(1, 1), '630');
      await tester.enterText(_height(1, 1), '180');
      // Someone else saves first.
      server.seedScore(scoringAssignmentId(1, 1), {
        'time_flown': 500,
        'launch_height': 150,
      });
      server
        ..entryStatus = 409
        ..entryCode = 'stale_revision';
      await tester.pump();
      await tester.tap(_save(1, 1));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('score-stale')), findsOneWidget);
      expect(find.textContaining('launch_height: 150'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('score-take-theirs')));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(_time(1, 1)).controller!.text, '8:20');
    },
  );

  testWidgets('Score check lists missing entries and jumps to the field', (
    tester,
  ) async {
    await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
    await tester.tap(find.byKey(const ValueKey('score-check')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('score-check-panel')), findsOneWidget);
    expect(find.text('Nothing entered yet.'), findsNWidgets(2));
  });

  testWidgets('moving to another group with unsaved edits asks first', (
    tester,
  ) async {
    await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
    await _activate(tester, 1, 1);
    await tester.enterText(_time(1, 1), '630');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('group-next')));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved scores'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('unsaved-stay')));
    await tester.pumpAndSettle();
    expect(find.text('Ann Lee'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('group-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('unsaved-discard')));
    await tester.pumpAndSettle();
    expect(find.text('Cy Fox'), findsOneWidget);
  });

  testWidgets('a locked round is read only and says why', (tester) async {
    final server = ScoringServer(
      matrix: drawnMatrix(round2Status: RoundStatus.locked),
    );
    await pumpScoringPage(tester, server, round: 2, group: 1);
    expect(find.text('This round is locked.'), findsWidgets);
    expect(tester.widget<TextField>(_time(2, 1)).enabled, isFalse);
  });

  testWidgets('a completed contest does not accept entry', (tester) async {
    final server = ScoringServer(
      contest: matrixContest(state: LifecycleState.completed),
    );
    await pumpScoringPage(tester, server, round: 1, group: 1);
    expect(find.textContaining('This contest is completed'), findsWidgets);
    expect(tester.widget<TextField>(_time(1, 1)).enabled, isFalse);
  });

  testWidgets('Enter in the time field moves to the height', (tester) async {
    await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
    await _activate(tester, 1, 1);
    await tester.tap(_time(1, 1));
    await tester.enterText(_time(1, 1), '630');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    final node = tester
        .widget<EditableText>(
          find.descendant(
            of: _height(1, 1),
            matching: find.byType(EditableText),
          ),
        )
        .focusNode;
    expect(node.hasFocus, isTrue);
  });

  testWidgets('no matrix links to the Matrix page', (tester) async {
    final server = ScoringServer(matrix: CurrentMatrix());
    await pumpScoringPage(tester, server);
    expect(find.text('This contest has no matrix yet.'), findsOneWidget);
    expect(find.byKey(const ValueKey('scoring-open-matrix')), findsOneWidget);
  });

  group('time and launch height captions', () {
    testWidgets('the time reads as m:ss once the field is left', (
      tester,
    ) async {
      await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
      await tester.tap(_row(1, 1));
      await tester.pumpAndSettle();
      await tester.tap(_time(1, 1));
      await tester.enterText(_time(1, 1), '630.4');
      await tester.pump();
      expect(tester.widget<TextField>(_time(1, 1)).controller!.text, '630.4');
      await tester.tap(_height(1, 1));
      await tester.pump();
      expect(tester.widget<TextField>(_time(1, 1)).controller!.text, '6:30.4');
    });

    testWidgets(
      'an untouched launch height shows nothing; a touched empty one says Required',
      (tester) async {
        await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
        await tester.tap(_row(1, 1));
        await tester.pumpAndSettle();
        expect(find.text('Required'), findsNothing);
        await tester.tap(_height(1, 1));
        await tester.pump();
        expect(find.text('Required'), findsNothing);
        await tester.tap(_time(1, 1));
        await tester.pump();
        expect(find.text('Required'), findsOneWidget);
      },
    );

    testWidgets('a valid launch height shows its height penalty', (
      tester,
    ) async {
      await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
      await tester.tap(_row(1, 1));
      await tester.pumpAndSettle();
      await tester.enterText(_height(1, 1), '250');
      await tester.pump();
      // 200 m at 0.5 plus 50 m at 3.0.
      expect(find.text('250 pts'), findsOneWidget);
    });
  });

  group('cell alignment', () {
    testWidgets('the penalties column is centered', (tester) async {
      await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
      final heading = tester.getCenter(find.text('Penalties'));
      final none = tester.getCenter(find.text('None').first);
      expect(none.dx, closeTo(heading.dx, 4));
    });

    testWidgets('no preview note sits under the scores', (tester) async {
      await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
      await tester.tap(_row(1, 1));
      await tester.pumpAndSettle();
      await tester.enterText(_time(1, 1), '630');
      await tester.enterText(_height(1, 1), '180');
      await tester.pump();
      expect(find.text('Preview, not saved'), findsNothing);
    });
  });

  group('lanes and teams follow the configuration', () {
    testWidgets('are left out when the contest does not use them', (
      tester,
    ) async {
      await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
      expect(find.text('Lane'), findsNothing);
      expect(find.text('No.'), findsNothing);
      expect(find.text('Pilot'), findsOneWidget);
      expect(find.text('Flying Gators'), findsNothing);
      expect(find.text('Pilot · team'), findsNothing);
    });

    testWidgets('are shown when the contest uses lanes and teams', (
      tester,
    ) async {
      await pumpScoringPage(
        tester,
        ScoringServer(
          core: {
            'lane_mode': 'Random',
            'teams_enabled': true,
            'team_pilot_count': 2,
          },
          matrix: drawnMatrix(lanes: true),
        ),
        round: 1,
        group: 1,
      );
      expect(find.text('Lane'), findsOneWidget);
      expect(find.text('Pilot · team'), findsOneWidget);
      expect(find.textContaining('Flying Gators'), findsWidgets);
    });

    testWidgets('pilot numbers take the first column when there are no lanes', (
      tester,
    ) async {
      await pumpScoringPage(
        tester,
        ScoringServer(core: {'participant_numbers_enabled': true}),
        round: 1,
        group: 1,
      );
      expect(find.text('Lane'), findsNothing);
      expect(find.text('No.'), findsOneWidget);
    });
  });

  group('landing field', () {
    Finder landing(int pilot) => find.byKey(
      ValueKey('score-landing-${scoringAssignmentId(1, pilot).value}'),
    );
    Future<ScoringServer> open(WidgetTester tester) async {
      final server = ScoringServer();
      await pumpScoringPage(tester, server, round: 1, group: 1);
      await tester.tap(_row(1, 1));
      await tester.pumpAndSettle();
      return server;
    }

    testWidgets('typing table points selects the band and names it', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(landing(1));
      await tester.pump();
      // Focused and empty: the hint lists the table's points.
      expect(find.text('Type table points: 50, 30 … 10'), findsOneWidget);
      expect(find.byKey(const ValueKey('landing-follows-tag')), findsOneWidget);
      await tester.enterText(landing(1), '30');
      await tester.pump();
      expect(find.text('Within 5 m · 30 pts'), findsOneWidget);
      final id = scoringAssignmentId(1, 1).value;
      final chip = tester.widget<ScoreLandingChip>(
        find.byKey(ValueKey('score-landing-$id-within_5m')),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('points that are not in the table are an error', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(landing(1));
      await tester.enterText(landing(1), '42');
      await tester.pump();
      expect(
        find.text('42 isn’t in the landing table. Use 50, 30 … 10'),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(_save(1, 1)).onPressed, isNull);
    });

    testWidgets('Up and Down step through the bands', (tester) async {
      await open(tester);
      await tester.tap(landing(1));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(tester.widget<TextField>(landing(1)).controller!.text, '50');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(tester.widget<TextField>(landing(1)).controller!.text, '30');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      // The last band is the end of the table.
      expect(tester.widget<TextField>(landing(1)).controller!.text, '10');
    });

    testWidgets('a chip fills the field, and the chips leave the Tab order', (
      tester,
    ) async {
      await open(tester);
      final id = scoringAssignmentId(1, 1).value;
      await tester.tap(find.byKey(ValueKey('score-landing-$id-within_10m')));
      await tester.pump();
      expect(tester.widget<TextField>(landing(1)).controller!.text, '10');
      expect(find.text('Within 10 m · 10'), findsOneWidget);
    });

    testWidgets('the saved landing is the matching table entry', (
      tester,
    ) async {
      final server = ScoringServer();
      await pumpScoringPage(tester, server, round: 1, group: 1);
      await tester.tap(_row(1, 1));
      await tester.pumpAndSettle();
      await tester.enterText(_time(1, 1), '630');
      await tester.enterText(_height(1, 1), '180');
      await tester.enterText(landing(1), '50');
      await tester.pump();
      await tester.tap(_save(1, 1));
      await tester.pumpAndSettle();
      expect(server.entries.single['components'], {
        'time_flown': 390,
        'launch_height': 180,
        'landing': 'within_1m',
      });
    });

    testWidgets('late landing and zeroing flags switch the field off', (
      tester,
    ) async {
      await open(tester);
      final id = scoringAssignmentId(1, 1).value;
      await tester.tap(find.byKey(ValueKey('score-late-$id')));
      await tester.pump();
      expect(tester.widget<TextField>(landing(1)).enabled, isFalse);
      expect(find.text('0 · late'), findsOneWidget);
    });
  });

  group('layout follows the design', () {
    testWidgets('navigation is left and actions are right', (tester) async {
      await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
      final first = tester.getTopLeft(
        find.byKey(const ValueKey('round-first')),
      );
      final action = tester.getTopRight(
        find.byKey(const ValueKey('score-save-all')),
      );
      final width = tester.view.physicalSize.width;
      expect(first.dx, closeTo(16, 4));
      expect(action.dx, closeTo(width - 16, 4));
    });

    testWidgets('the status line starts at the left edge', (tester) async {
      await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
      final chip = tester.getTopLeft(find.text('Round not flown'));
      expect(chip.dx, lessThan(60));
    });

    testWidgets('the whole active row is highlighted and holds the band card', (
      tester,
    ) async {
      await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
      await tester.tap(_row(1, 1));
      await tester.pumpAndSettle();
      final row = tester.getRect(_row(1, 1));
      final table = tester.getRect(find.byKey(const ValueKey('score-table')));
      // Full width of the table, less its border.
      expect(row.width, closeTo(table.width, 3));
      final band = tester.getRect(
        find.byKey(ValueKey('score-band-${scoringAssignmentId(1, 1).value}')),
      );
      // The band is a card inside the highlighted row.
      expect(band.left, greaterThan(row.left));
      expect(band.right, lessThan(row.right));
    });

    testWidgets('a missing field is explained under the field, not by Save', (
      tester,
    ) async {
      await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
      await tester.tap(_row(1, 1));
      await tester.pumpAndSettle();
      await tester.enterText(_time(1, 1), '630');
      await tester.pump();
      // The launch height is checked only once it has been touched.
      expect(find.text('Required'), findsNothing);
      await tester.tap(_height(1, 1));
      await tester.pump();
      await tester.tap(_time(1, 1));
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);
      expect(find.textContaining('Correct the marked fields'), findsNothing);
      await tester.enterText(_time(1, 1), '');
      await tester.enterText(_height(1, 1), '180');
      await tester.pump();
      expect(find.text('Time flown is needed with a height.'), findsOneWidget);
    });

    testWidgets('Save row and Revert are left, the hint is right', (
      tester,
    ) async {
      await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
      await tester.tap(_row(1, 1));
      await tester.pumpAndSettle();
      final save = tester.getTopLeft(_save(1, 1));
      final hint = tester.getTopRight(find.textContaining('Enter moves on'));
      final band = tester.getRect(
        find.byKey(ValueKey('score-band-${scoringAssignmentId(1, 1).value}')),
      );
      expect(save.dx, closeTo(band.left + 16, 2));
      expect(hint.dx, closeTo(band.right - 16, 2));
    });
  });
}
