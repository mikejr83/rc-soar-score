import 'package:flutter/material.dart';
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

  testWidgets(
    'removing an applied cumulative penalty asks for a reason first',
    (tester) async {
      final server = ScoringServer();
      server.seedScore(scoringAssignmentId(1, 1), {
        'time_flown': 540,
        'launch_height': 200,
        'cumulative_penalty': 5,
      });
      await pumpScoringPage(tester, server, round: 1, group: 1);
      await _activate(tester, 1, 1);
      await tester.enterText(
        find.byKey(const ValueKey('cumulative-penalty')),
        '0',
      );
      await tester.pump();
      await tester.tap(_save(1, 1));
      await tester.pumpAndSettle();
      // The dialog is open, nothing is saved yet.
      expect(find.byKey(const ValueKey('penalty-removal-dialog')), findsOneWidget);
      expect(server.entries, isEmpty);
      // The button is off while the reason is blank.
      expect(
        tester.widget<FilledButton>(
          find.byKey(const ValueKey('penalty-removal-confirm')),
        ).onPressed,
        isNull,
      );
      // Cancelling keeps the values and saves nothing.
      await tester.tap(find.byKey(const ValueKey('penalty-removal-cancel')));
      await tester.pumpAndSettle();
      expect(server.entries, isEmpty);
      expect(tester.widget<TextField>(
        find.byKey(const ValueKey('cumulative-penalty')),
      ).controller!.text,
      '0',
      );
      // A reason records the removal.
      await tester.tap(_save(1, 1));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('penalty-removal-reason')),
        'Timer slip misread',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('penalty-removal-confirm')));
      await tester.pumpAndSettle();
      expect(server.entries, hasLength(1));
      final body = server.entries.single;
      expect(
        body['components'],
        {'time_flown': 540, 'launch_height': 200, 'cumulative_penalty': 0},
      );
      expect(body['reason'], 'Timer slip misread');
    },
  );

  testWidgets(
    'saving several removals asks one shared reason first',
    (tester) async {
      final server = ScoringServer();
      server.seedScore(scoringAssignmentId(1, 1), {
        'time_flown': 540,
        'launch_height': 200,
        'cumulative_penalty': 5,
      });
      server.seedScore(scoringAssignmentId(1, 2), {
        'time_flown': 500,
        'launch_height': 180,
        'cumulative_penalty': 10,
      });
      await pumpScoringPage(tester, server, round: 1, group: 1);
      // Both pilots drop their applied penalty to 0.
      for (final pilot in [1, 2]) {
        await _activate(tester, 1, pilot);
        await tester.enterText(
          find.byKey(const ValueKey('cumulative-penalty')),
          '0',
        );
        await tester.pump();
      }
      // The toolbar offers the bulk save, nothing is saved yet.
      expect(find.text('Save 2 rows'), findsOneWidget);
      expect(server.entries, isEmpty);
      await tester.tap(find.byKey(const ValueKey('score-save-all')));
      await tester.pumpAndSettle();
      // One dialog names both pilots; the reason is blank, so nothing saves.
      expect(find.byKey(const ValueKey('penalty-removal-dialog')), findsOneWidget);
      expect(find.text('Remove 2 penalties?'), findsOneWidget);
      expect(find.text('Ann Lee, Bo Ray'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(
          find.byKey(const ValueKey('penalty-removal-confirm')),
        ).onPressed,
        isNull,
      );
      expect(server.entries, isEmpty);
      // Recording the reason saves both removals under it.
      await tester.enterText(
        find.byKey(const ValueKey('penalty-removal-reason')),
        'Timer slip misread',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('penalty-removal-confirm')));
      await tester.pumpAndSettle();
      expect(server.entries, hasLength(2));
      for (final body in server.entries) {
        expect(body['reason'], 'Timer slip misread');
        expect(body['components']['cumulative_penalty'], 0);
      }
      expect(find.text('Saved 2 rows.'), findsOneWidget);
    },
  );

  testWidgets('a bulk save of a removal plus an edit records both reasons', (
    tester,
  ) async {
    final server = ScoringServer();
    server.seedScore(scoringAssignmentId(1, 1), {
      'time_flown': 540,
      'launch_height': 200,
      'cumulative_penalty': 5,
    });
    await pumpScoringPage(tester, server, round: 1, group: 1);
    await _activate(tester, 1, 1);
    // Drop the applied penalty (a removal) and correct another pilot's time.
    await tester.enterText(find.byKey(const ValueKey('cumulative-penalty')), '0');
    await tester.pump();
    await _activate(tester, 1, 2);
    await tester.enterText(_time(1, 2), '630');
    await tester.enterText(_height(1, 2), '180');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('score-save-all')));
    await tester.pumpAndSettle();
    // Only one removal, so the dialog names that pilot alone.
    expect(find.text('Remove Ann Lee\'s penalty?'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('penalty-removal-reason')),
      'Timer slip misread',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('penalty-removal-confirm')));
    await tester.pumpAndSettle();
    expect(server.entries, hasLength(2));
    final removal = server.entries.firstWhere(
      (b) => b['components']['cumulative_penalty'] == 0,
    );
    final edit = server.entries.firstWhere(
      (b) => !b['components'].containsKey('cumulative_penalty'),
    );
    expect(removal['reason'], 'Timer slip misread');
    expect(edit['reason'], 'Entered on the scoring page');
  });

  testWidgets(
    'a bulk save with one removal aborts when the reason is cancelled',
    (tester) async {
      final server = ScoringServer();
      server.seedScore(scoringAssignmentId(1, 1), {
        'time_flown': 540,
        'launch_height': 200,
        'cumulative_penalty': 5,
      });
      await pumpScoringPage(tester, server, round: 1, group: 1);
      await _activate(tester, 1, 1);
      // Drop the applied penalty so the save would remove it.
      await tester.enterText(
        find.byKey(const ValueKey('cumulative-penalty')),
        '0',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('score-save-all')));
      await tester.pumpAndSettle();
      // The dialog opens before anything saves.
      expect(
        find.byKey(const ValueKey('penalty-removal-dialog')),
        findsOneWidget,
      );
      expect(server.entries, isEmpty);
      // Cancelling aborts the whole save: nothing saves, the values stay,
      // and no snackbar reports a save.
      await tester.tap(find.byKey(const ValueKey('penalty-removal-cancel')));
      await tester.pumpAndSettle();
      expect(server.entries, isEmpty);
      expect(
        tester.widget<TextField>(
          find.byKey(const ValueKey('cumulative-penalty')),
        ).controller!.text,
        '0',
      );
      expect(find.text('1 unsaved row'), findsOneWidget);
      expect(find.text('Saved 1 row.'), findsNothing);
    },
  );

  testWidgets(
    'a failed penalty-removal save stays pending and retries keep the reason',
    (tester) async {
      final server = ScoringServer();
      server.seedScore(scoringAssignmentId(1, 1), {
        'time_flown': 540,
        'launch_height': 200,
        'cumulative_penalty': 5,
      });
      await pumpScoringPage(tester, server, round: 1, group: 1);
      await _activate(tester, 1, 1);
      await tester.enterText(
        find.byKey(const ValueKey('cumulative-penalty')),
        '0',
      );
      await tester.pump();
      server.entryFailures[scoringAssignmentId(1, 1)] = (500, 'boom');
      await tester.tap(_save(1, 1));
      await tester.pumpAndSettle();
      // One reason, recorded when the dialog confirms.
      await tester.enterText(
        find.byKey(const ValueKey('penalty-removal-reason')),
        'Timer slip misread',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('penalty-removal-confirm')));
      await tester.pumpAndSettle();
      // The failed removal waits on its row, reason recorded with it.
      expect(find.byKey(const ValueKey('score-save-failed')), findsOneWidget);
      expect(server.entries, hasLength(1));
      expect(server.entries.first['reason'], 'Timer slip misread');
      // A save-all does not retry it under another reason.
      await tester.tap(find.byKey(const ValueKey('score-save-all')));
      await tester.pumpAndSettle();
      expect(server.entries, hasLength(1));
      expect(find.text('Saved 1 row.'), findsNothing);
      expect(find.byKey(const ValueKey('score-save-failed')), findsOneWidget);
      // Once the server answers again, the row's Save retries without a dialog.
      server.entryFailures.clear();
      await tester.tap(_save(1, 1));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('penalty-removal-dialog')), findsNothing);
      expect(find.byKey(const ValueKey('score-save-failed')), findsNothing);
      expect(server.entries, hasLength(2));
      expect(server.entries.last['reason'], 'Timer slip misread');
    },
  );

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

  testWidgets(
    'a stale penalty-removal is not save-alled and Keep mine keeps its reason',
    (tester) async {
      final server = ScoringServer();
      server.seedScore(scoringAssignmentId(1, 1), {
        'time_flown': 540,
        'launch_height': 200,
        'cumulative_penalty': 5,
      });
      // A newer revision lands while the director is working: the entry
      // conflicts as stale.
      server.seedCorrection(
        scoringAssignmentId(1, 1),
        {
          'time_flown': 500,
          'launch_height': 150,
          'cumulative_penalty': 5,
        },
        'correction',
      );
      server.entryFailures[scoringAssignmentId(1, 1)] = (409, 'stale_revision');
      await pumpScoringPage(tester, server, round: 1, group: 1);
      await _activate(tester, 1, 1);
      await tester.enterText(
        find.byKey(const ValueKey('cumulative-penalty')),
        '0',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('score-save-all')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('penalty-removal-reason')),
        'Timer slip misread',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('penalty-removal-confirm')));
      await tester.pumpAndSettle();
      // The conflict waits on the row, reason recorded with it.
      expect(find.byKey(const ValueKey('score-stale')), findsOneWidget);
      expect(server.entries, hasLength(1));
      expect(server.entries.first['reason'], 'Timer slip misread');
      // A second save-all does not ask again or force the stale removal.
      await tester.tap(find.byKey(const ValueKey('score-save-all')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('penalty-removal-dialog')), findsNothing);
      expect(server.entries, hasLength(1));
      expect(find.text('Saved 1 row.'), findsNothing);
      expect(find.byKey(const ValueKey('score-stale')), findsOneWidget);
      // Keep mine re-saves the removal under the director-entered reason, not
      // the generic conflict message.
      server.entryFailures.clear();
      await tester.tap(find.byKey(const ValueKey('score-keep-mine')));
      await tester.pumpAndSettle();
      expect(server.entries, hasLength(2));
      expect(
        (server.entries.last['components'] as Map)['cumulative_penalty'],
        0,
      );
      expect(server.entries.last['reason'], 'Timer slip misread');
      expect(find.byKey(const ValueKey('score-stale')), findsNothing);
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
    testWidgets('a landing value is right aligned and a dash is centered', (
      tester,
    ) async {
      await pumpScoringPage(tester, ScoringServer(), round: 1, group: 1);
      await tester.tap(_row(1, 1));
      await tester.pumpAndSettle();
      // Bo Ray has no landing: the dash sits in the middle of the column.
      final dash = tester.getCenter(find.text('–').first);
      final head = tester.getRect(find.text('Landing · flags'));
      expect(dash.dx, lessThan(head.right));
      final id = scoringAssignmentId(1, 1).value;
      await tester.tap(find.byKey(ValueKey('score-landing-$id-within_1m')));
      await tester.pump();
      final value = tester.getTopRight(
        find
            .descendant(of: _row(1, 1), matching: find.text('Within 1 m'))
            .first,
      );
      expect(value.dx, closeTo(head.right, 12));
    });

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
