import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/matrix_move_support.dart';
import '../support/matrix_test_support.dart';

/// The targets of a move (#263): marks, blocks and lanes.
void main() {
  group('targets', () {
    testWidgets('are marked recommended or not ideal with the reason', (
      tester,
    ) async {
      final server = moveServer();
      server.scoredAssignments.add((1, 3));
      await pumpMatrixPage(tester, server);
      await openMove(tester, 'Ann Lee', 1);

      // Round 1, group B holds teammate Cy Fox, who has a score.
      expect(markOf(tester, 'B'), 'Not ideal');
      expect(
        noteOf(tester, 'B'),
        'Pilots in this group already have scores. '
        'A teammate flies in this group.',
      );
      expect(groupEnabled(tester, 'B'), isTrue);
      // The group the pilot flies in now cannot be chosen.
      expect(groupEnabled(tester, 'A'), isFalse);
      expect(noteOf(tester, 'A'), 'The pilot flies in this group now.');
    });

    testWidgets('a round that appears completed is not ideal', (tester) async {
      final server = moveServer();
      for (final pilot in [1, 2, 3, 4]) {
        server.scoredAssignments.add((2, pilot));
      }
      await pumpMatrixPage(tester, server);
      await openMove(tester, 'Ann Lee', 1);
      await tester.tap(keyOf('move-round'));
      await settle(tester);
      await tester.tap(find.text('Round 2').last);
      await settle(tester);
      expect(markOf(tester, 'B'), 'Not ideal');
      expect(
        noteOf(tester, 'B'),
        'Pilots in this group already have scores. '
        'This round appears to be completed.',
      );
    });

    testWidgets('a group the pilot is already part of in another round is '
        'blocked', (tester) async {
      await pumpMatrixPage(tester, moveServer());
      // Ann flies in round 2, group A. Moving Bo Ray (round 1, group A) is
      // fine, but Ann's round 1 move cannot go to round 2, group A.
      await openMove(tester, 'Ann Lee', 1);
      await tester.tap(keyOf('move-round'));
      await settle(tester);
      await tester.tap(find.text('Round 2').last);
      await settle(tester);
      expect(groupEnabled(tester, 'A'), isFalse);
      expect(
        noteOf(tester, 'A'),
        'The pilot already flies in this group in round 2.',
      );
      expect(groupEnabled(tester, 'B'), isTrue);
      // Tapping a blocked group chooses nothing.
      await tapAndSettle(tester, keyOf('move-group-A'));
      await enterReason(tester, 'x');
      await tapAndSettle(tester, keyOf('move-confirm'));
      expect(find.text('Choose a group to move the pilot to.'), findsOneWidget);
    });

    testWidgets('locked groups and rounds say to unlock them', (tester) async {
      await pumpMatrixPage(
        tester,
        moveServer(lockedGroups: {(1, 2)}, round2Status: RoundStatus.locked),
      );
      await openMove(tester, 'Ann Lee', 1);
      expect(groupEnabled(tester, 'B'), isFalse);
      expect(
        noteOf(tester, 'B'),
        'This group is locked. Unlock the group first.',
      );
      await tester.tap(keyOf('move-round'));
      await settle(tester);
      await tester.tap(find.text('Round 2').last);
      await settle(tester);
      expect(groupEnabled(tester, 'B'), isFalse);
      expect(
        noteOf(tester, 'B'),
        'This round is locked. Unlock the round first.',
      );
    });

    testWidgets('a locked group of the pilot blocks the move', (tester) async {
      await pumpMatrixPage(tester, moveServer(lockedGroups: {(1, 1)}));
      await openMove(tester, 'Ann Lee', 1);
      expect(keyOf('move-source-block'), findsOneWidget);
      expect(
        find.text(
          'The pilot\'s group is locked. Unlock the group before moving the '
          'pilot.',
        ),
        findsOneWidget,
      );
      expect(groupEnabled(tester, 'B'), isFalse);
      expect(
        tester.widget<FilledButton>(keyOf('move-confirm')).onPressed,
        isNull,
      );
    });

    testWidgets('a locked score blocks the move', (tester) async {
      final server = moveServer();
      server.scoredAssignments.add((1, 1));
      server.lockedScores.add((1, 1));
      await pumpMatrixPage(tester, server);
      await openMove(tester, 'Ann Lee', 1);
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
      await pumpMatrixPage(tester, moveServer(protection: true));
      await openMove(tester, 'Ann Lee', 1);
      expect(groupEnabled(tester, 'B'), isFalse);
      expect(
        noteOf(tester, 'B'),
        'Team protection is on and a teammate flies in this group.',
      );
    });
  });

  group('lanes', () {
    testWidgets('a lane is chosen and taken ones are named', (tester) async {
      final server = moveServer(lanes: true);
      await pumpMatrixPage(tester, server);
      await openMove(tester, 'Ann Lee', 1);
      expect(find.text('Now flying round 1, group A, lane 2.'), findsOneWidget);
      await tapAndSettle(tester, keyOf('move-group-B'));
      await enterReason(tester, 'Swap');
      // No lane yet.
      await tapAndSettle(tester, keyOf('move-confirm'));
      expect(find.text('Choose a lane.'), findsOneWidget);
      expect(server.moves, isEmpty);

      await tester.tap(find.byType(DropdownButtonFormField<int>).last);
      await settle(tester);
      // Round 1, group B: Cy Fox has lane 1, Di Park lane 2.
      expect(find.text('Lane 1, taken by Cy Fox'), findsOneWidget);
      expect(find.text('Lane 2, taken by Di Park'), findsOneWidget);
    });

    testWidgets('a full group in another round has no free lane', (
      tester,
    ) async {
      await pumpMatrixPage(tester, moveServer(lanes: true));
      await openMove(tester, 'Di Park', 1);
      await tester.tap(keyOf('move-round'));
      await settle(tester);
      await tester.tap(find.text('Round 2').last);
      await settle(tester);
      await tapAndSettle(tester, keyOf('move-group-A'));
      await tester.tap(find.byType(DropdownButtonFormField<int>).last);
      await settle(tester);
      expect(find.text('Lane 1, taken by Ann Lee'), findsOneWidget);
      expect(find.text('Lane 2, taken by Cy Fox'), findsOneWidget);
    });
  });
}
