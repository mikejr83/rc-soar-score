import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/widgets/matrix/pilot_row_tile.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/matrix_test_support.dart';

/// Moving a pilot from the matrix page (#263). The fixture: round 1 is
/// {1,2} {3,4}, round 2 is {1,3} {2,4}; pilots 1 and 3 are teammates, so are
/// 2 and 4.
MatrixServer _server({
  bool lanes = false,
  Contest? contest,
  Set<(int, int)> lockedGroups = const {},
  RoundStatus round2Status = RoundStatus.open,
  bool protection = false,
}) => MatrixServer(
  contest: contest ?? matrixContest(state: LifecycleState.running),
  configuration: matrixConfiguration({
    if (lanes) 'lane_mode': 'Random',
    'teams_enabled': true,
    'team_pilot_count': 2,
    if (protection) 'team_protection': true,
  }),
  matrix: drawnMatrix(
    lanes: lanes,
    lockedGroups: lockedGroups,
    round2Status: round2Status,
  ),
);

Finder _tile(String name, int round) => find.byWidgetPredicate(
  (w) => w is PilotRowTile && w.slot.pilot.name == name && w.round == round,
  description: '$name in round $round',
);

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _settle(WidgetTester tester) => tester.pumpAndSettle();

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _settle(tester);
}

/// Selects [name], opens the pilot actions of the tile in [round] and picks
/// Move.
Future<void> _openMove(WidgetTester tester, String name, int round) async {
  await _tap(tester, _tile(name, round));
  await _tap(
    tester,
    find.descendant(of: _tile(name, round), matching: _key('pilot-actions')),
  );
  await _tap(tester, _key('pilot-action-move'));
}

Future<void> _reason(WidgetTester tester, String text) async {
  await tester.enterText(_key('move-reason'), text);
  await tester.pump();
}

/// The text under the group row [letter] of the move dialog.
String? _note(WidgetTester tester, String letter) {
  final note = _key('move-note-$letter');
  return note.evaluate().isEmpty ? null : tester.widget<Text>(note).data;
}

String _mark(WidgetTester tester, String letter) =>
    tester.widget<Text>(_key('move-mark-$letter')).data!;

bool _enabled(WidgetTester tester, String letter) =>
    tester.widget<ListTile>(_key('move-group-$letter')).enabled;

void main() {
  group('moving a pilot', () {
    testWidgets('a pilot moves to another group and the grid says so', (
      tester,
    ) async {
      final server = _server();
      await pumpMatrixPage(tester, server);
      await _openMove(tester, 'Ann Lee', 1);

      expect(find.text('Move Ann Lee'), findsOneWidget);
      expect(find.text('Now flying round 1, group A.'), findsOneWidget);
      // Round 2, group B holds pilots 2 and 4, who are on the other team.
      await tester.tap(_key('move-round'));
      await _settle(tester);
      await tester.tap(find.text('Round 2').last);
      await _settle(tester);
      expect(_mark(tester, 'B'), 'Recommended');
      await _tap(tester, _key('move-group-B'));
      await _reason(tester, 'Lane swap for the sun');
      await _tap(tester, _key('move-confirm'));

      expect(server.moves, hasLength(1));
      expect(server.moves.single['assignment'], assignmentId(1, 1).value);
      final body = server.moves.single['body'] as Map<String, dynamic>;
      expect(body['scheduled_round_id'], isNotNull);
      expect(body['group'], 2);
      expect(body['reason'], 'Lane swap for the sun');
      expect(body['id'], isNotNull);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Ann Lee moved.'), findsOneWidget);
      // The grid shows the Moved label on the moved tile, and the panel the
      // reason.
      expect(
        find.descendant(of: _tile('Ann Lee', 2), matching: _key('moved-label')),
        findsOneWidget,
      );
      expect(find.text('Moved'), findsOneWidget);
      expect(find.text('Moves'), findsOneWidget);
      expect(find.text('Round 2: Lane swap for the sun'), findsOneWidget);
    });

    testWidgets('a reason is required and the dialog stays', (tester) async {
      final server = _server();
      await pumpMatrixPage(tester, server);
      await _openMove(tester, 'Ann Lee', 1);
      await _tap(tester, _key('move-confirm'));
      expect(find.text('Choose a group to move the pilot to.'), findsOneWidget);
      expect(find.text('Enter a reason.'), findsOneWidget);
      await _tap(tester, _key('move-group-B'));
      await _tap(tester, _key('move-confirm'));
      expect(find.text('Choose a group to move the pilot to.'), findsNothing);
      expect(find.text('Enter a reason.'), findsOneWidget);
      expect(server.moves, isEmpty);
    });

    testWidgets('cancel leaves the matrix as it was', (tester) async {
      final server = _server();
      await pumpMatrixPage(tester, server);
      await _openMove(tester, 'Ann Lee', 1);
      await _tap(tester, _key('move-cancel'));
      expect(find.byType(AlertDialog), findsNothing);
      expect(server.moves, isEmpty);
      expect(_key('moved-label'), findsNothing);
    });
  });

  group('targets', () {
    testWidgets('are marked recommended or not ideal with the reason', (
      tester,
    ) async {
      final server = _server();
      server.scoredAssignments.add((1, 3));
      await pumpMatrixPage(tester, server);
      await _openMove(tester, 'Ann Lee', 1);

      // Round 1, group B holds teammate Cy Fox, who has a score.
      expect(_mark(tester, 'B'), 'Not ideal');
      expect(
        _note(tester, 'B'),
        'Pilots in this group already have scores. '
        'A teammate flies in this group.',
      );
      expect(_enabled(tester, 'B'), isTrue);
      // The group the pilot flies in now cannot be chosen.
      expect(_enabled(tester, 'A'), isFalse);
      expect(_note(tester, 'A'), 'The pilot flies in this group now.');
    });

    testWidgets('a round that appears completed is not ideal', (tester) async {
      final server = _server();
      for (final pilot in [1, 2, 3, 4]) {
        server.scoredAssignments.add((2, pilot));
      }
      await pumpMatrixPage(tester, server);
      await _openMove(tester, 'Ann Lee', 1);
      await tester.tap(_key('move-round'));
      await _settle(tester);
      await tester.tap(find.text('Round 2').last);
      await _settle(tester);
      expect(_mark(tester, 'B'), 'Not ideal');
      expect(
        _note(tester, 'B'),
        'Pilots in this group already have scores. '
        'This round appears to be completed.',
      );
    });

    testWidgets('a group the pilot is already part of in another round is '
        'blocked', (tester) async {
      await pumpMatrixPage(tester, _server());
      // Ann flies in round 2, group A. Moving Bo Ray (round 1, group A) is
      // fine, but Ann's round 1 move cannot go to round 2, group A.
      await _openMove(tester, 'Ann Lee', 1);
      await tester.tap(_key('move-round'));
      await _settle(tester);
      await tester.tap(find.text('Round 2').last);
      await _settle(tester);
      expect(_enabled(tester, 'A'), isFalse);
      expect(
        _note(tester, 'A'),
        'The pilot already flies in this group in round 2.',
      );
      expect(_enabled(tester, 'B'), isTrue);
      // Tapping a blocked group chooses nothing.
      await _tap(tester, _key('move-group-A'));
      await _reason(tester, 'x');
      await _tap(tester, _key('move-confirm'));
      expect(find.text('Choose a group to move the pilot to.'), findsOneWidget);
    });

    testWidgets('locked groups and rounds say to unlock them', (tester) async {
      await pumpMatrixPage(
        tester,
        _server(lockedGroups: {(1, 2)}, round2Status: RoundStatus.locked),
      );
      await _openMove(tester, 'Ann Lee', 1);
      expect(_enabled(tester, 'B'), isFalse);
      expect(
        _note(tester, 'B'),
        'This group is locked. Unlock the group first.',
      );
      await tester.tap(_key('move-round'));
      await _settle(tester);
      await tester.tap(find.text('Round 2').last);
      await _settle(tester);
      expect(_enabled(tester, 'B'), isFalse);
      expect(
        _note(tester, 'B'),
        'This round is locked. Unlock the round first.',
      );
    });

    testWidgets('a locked group of the pilot blocks the move', (tester) async {
      await pumpMatrixPage(tester, _server(lockedGroups: {(1, 1)}));
      await _openMove(tester, 'Ann Lee', 1);
      expect(_key('move-source-block'), findsOneWidget);
      expect(
        find.text(
          'The pilot\'s group is locked. Unlock the group before moving the '
          'pilot.',
        ),
        findsOneWidget,
      );
      expect(_enabled(tester, 'B'), isFalse);
      expect(
        tester.widget<FilledButton>(_key('move-confirm')).onPressed,
        isNull,
      );
    });

    testWidgets('a locked score blocks the move', (tester) async {
      final server = _server();
      server.scoredAssignments.add((1, 1));
      server.lockedScores.add((1, 1));
      await pumpMatrixPage(tester, server);
      await _openMove(tester, 'Ann Lee', 1);
      expect(
        find.text(
          'The pilot\'s score is locked. Unlock the score before moving the '
          'pilot.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('team protection blocks a group with a teammate', (
      tester,
    ) async {
      await pumpMatrixPage(tester, _server(protection: true));
      await _openMove(tester, 'Ann Lee', 1);
      expect(_enabled(tester, 'B'), isFalse);
      expect(
        _note(tester, 'B'),
        'Team protection is on and a teammate flies in this group.',
      );
    });
  });

  group('a scored pilot', () {
    testWidgets('is warned and the button names the consequence', (
      tester,
    ) async {
      final server = _server();
      server.scoredAssignments.add((1, 1));
      await pumpMatrixPage(tester, server);
      await _openMove(tester, 'Ann Lee', 1);

      expect(_key('move-score-warning'), findsOneWidget);
      expect(find.textContaining('not the standard way'), findsOneWidget);
      expect(find.text('Move pilot'), findsNothing);
      expect(find.text('Discard score and move'), findsOneWidget);

      await _tap(tester, _key('move-group-B'));
      await _reason(tester, 'Scored in the wrong group');
      await _tap(tester, _key('move-confirm'));
      expect(server.moves, hasLength(1));
    });

    testWidgets('an unscored pilot gets no warning', (tester) async {
      await pumpMatrixPage(tester, _server());
      await _openMove(tester, 'Ann Lee', 1);
      expect(_key('move-score-warning'), findsNothing);
      expect(find.text('Move pilot'), findsOneWidget);
    });
  });

  group('lanes', () {
    testWidgets('a lane is chosen and taken ones are named', (tester) async {
      final server = _server(lanes: true);
      await pumpMatrixPage(tester, server);
      await _openMove(tester, 'Ann Lee', 1);
      expect(find.text('Now flying round 1, group A, lane 2.'), findsOneWidget);
      await _tap(tester, _key('move-group-B'));
      await _reason(tester, 'Swap');
      // No lane yet.
      await _tap(tester, _key('move-confirm'));
      expect(find.text('Choose a lane.'), findsOneWidget);
      expect(server.moves, isEmpty);

      await tester.tap(find.byType(DropdownButtonFormField<int>).last);
      await _settle(tester);
      // Round 1, group B: Cy Fox has lane 1, Di Park lane 2.
      expect(find.text('Lane 1, taken by Cy Fox'), findsOneWidget);
      expect(find.text('Lane 2, taken by Di Park'), findsOneWidget);
    });

    testWidgets('a full group in another round has no free lane', (
      tester,
    ) async {
      await pumpMatrixPage(tester, _server(lanes: true));
      await _openMove(tester, 'Di Park', 1);
      await tester.tap(_key('move-round'));
      await _settle(tester);
      await tester.tap(find.text('Round 2').last);
      await _settle(tester);
      await _tap(tester, _key('move-group-A'));
      await tester.tap(find.byType(DropdownButtonFormField<int>).last);
      await _settle(tester);
      expect(find.text('Lane 1, taken by Ann Lee'), findsOneWidget);
      expect(find.text('Lane 2, taken by Cy Fox'), findsOneWidget);
    });
  });

  group('errors', () {
    testWidgets('a refused move keeps the dialog and the values', (
      tester,
    ) async {
      final server = _server()
        ..moveStatus = 409
        ..moveCode = 'team_conflict'
        ..moveError = 'a teammate already flies in this group';
      await pumpMatrixPage(tester, server);
      await _openMove(tester, 'Ann Lee', 1);
      await _tap(tester, _key('move-group-B'));
      await _reason(tester, 'Keep this text');
      await _tap(tester, _key('move-confirm'));

      expect(_key('move-error'), findsOneWidget);
      expect(find.textContaining('teammate'), findsWidgets);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        tester.widget<TextField>(_key('move-reason')).controller!.text,
        'Keep this text',
      );
      // The grid is as it was.
      expect(_key('moved-label'), findsNothing);

      // Trying again sends the same request id.
      server.moveStatus = 201;
      await _tap(tester, _key('move-confirm'));
      expect(server.moves, hasLength(2));
      expect(
        (server.moves.first['body'] as Map)['id'],
        (server.moves.last['body'] as Map)['id'],
      );
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('a stale matrix offers Reload', (tester) async {
      final server = _server()
        ..moveStatus = 409
        ..moveCode = 'group_locked'
        ..moveError = 'group 2 is locked';
      await pumpMatrixPage(tester, server);
      await _openMove(tester, 'Ann Lee', 1);
      await _tap(tester, _key('move-group-B'));
      await _reason(tester, 'x');
      await _tap(tester, _key('move-confirm'));

      expect(
        find.text(
          'The matrix or the contest changed since this page loaded. Nothing '
          'was moved. Reload to see the current matrix.',
        ),
        findsOneWidget,
      );
      expect(_key('move-confirm'), findsNothing);
      await _tap(tester, _key('move-reload'));
      expect(find.byType(AlertDialog), findsNothing);
      expect(_key('moved-label'), findsNothing);
    });

    testWidgets('a lost connection says nothing was moved', (tester) async {
      final server = _server();
      await pumpMatrixPage(tester, server);
      await _openMove(tester, 'Ann Lee', 1);
      await _tap(tester, _key('move-group-B'));
      await _reason(tester, 'x');
      server.offline = true;
      await _tap(tester, _key('move-confirm'));
      expect(
        find.text(
          'Soar Score can\'t reach the server. Nothing was moved. Try again.',
        ),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('scores that cannot be read stop the move', (tester) async {
      final server = _server()..scoresStatus = 500;
      await pumpMatrixPage(tester, server);
      await _openMove(tester, 'Ann Lee', 1);
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        find.textContaining('The scores could not be checked'),
        findsOneWidget,
      );
    });
  });

  group('when moving is off', () {
    testWidgets('a locked contest shows Move off with the reason', (
      tester,
    ) async {
      await pumpMatrixPage(
        tester,
        _server(
          contest: matrixContest(
            state: LifecycleState.running,
            lock: AdminLock.locked,
          ),
        ),
      );
      await _tap(tester, _tile('Ann Lee', 1));
      await _tap(
        tester,
        find.descendant(
          of: _tile('Ann Lee', 1),
          matching: _key('pilot-actions'),
        ),
      );
      expect(
        tester.widget<PopupMenuItem<void>>(_key('pilot-action-move')).enabled,
        isFalse,
      );
      expect(
        find.text(
          'Administration is locked. Unlock the contest to move a pilot.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a completed contest shows Move off with the reason', (
      tester,
    ) async {
      await pumpMatrixPage(
        tester,
        _server(contest: matrixContest(state: LifecycleState.completed)),
      );
      await _tap(tester, _tile('Ann Lee', 1));
      await _tap(
        tester,
        find.descendant(
          of: _tile('Ann Lee', 1),
          matching: _key('pilot-actions'),
        ),
      );
      expect(
        find.text(
          'Pilots can be moved once the matrix is drawn and until the '
          'contest is complete.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('only the highlighted pilot has the menu', (tester) async {
      await pumpMatrixPage(tester, _server());
      expect(_key('pilot-actions'), findsNothing);
      await _tap(tester, _tile('Ann Lee', 1));
      expect(_key('pilot-actions'), findsNWidgets(2));
    });
  });
}
