import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';

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
    expect(find.textContaining('Seconds go up to 59'), findsOneWidget);
    // The rejected input is kept.
    expect(tester.widget<TextField>(_time(1, 1)).controller!.text, '675');
  });

  testWidgets('a time at the working time is rejected', (tester) async {
    await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
    await _activate(tester, 1, 1);
    await tester.enterText(_time(1, 1), '1000');
    await tester.pump();
    expect(find.textContaining('Over the working time'), findsOneWidget);
    expect(find.textContaining('9:59'), findsOneWidget);
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
    final chip = tester.widget<ChoiceChip>(
      find.byKey(ValueKey('score-landing-$id-within_1m')),
    );
    expect(chip.selected, isFalse);
    expect(chip.onSelected, isNull);
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
    expect(tester.widget<TextField>(_time(1, 1)).controller!.text, '630');

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
      expect(tester.widget<TextField>(_time(1, 1)).controller!.text, '820');
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
}
