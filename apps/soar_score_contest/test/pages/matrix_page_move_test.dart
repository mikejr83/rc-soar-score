import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/matrix_move_support.dart';
import '../support/matrix_test_support.dart';

/// Moving a pilot from the matrix page (#263): the flow and when it is off.
void main() {
  group('moving a pilot', () {
    testWidgets('a pilot moves to another group and the grid says so', (
      tester,
    ) async {
      final server = moveServer();
      await pumpMatrixPage(tester, server);
      await openMove(tester, 'Ann Lee', 1);

      expect(find.text('Move Ann Lee'), findsOneWidget);
      expect(find.text('Now flying round 1, group A.'), findsOneWidget);
      // Round 2, group B holds pilots 2 and 4, who are on the other team.
      await tester.tap(keyOf('move-round'));
      await settle(tester);
      await tester.tap(find.text('Round 2').last);
      await settle(tester);
      expect(markOf(tester, 'B'), 'Recommended');
      await tapAndSettle(tester, keyOf('move-group-B'));
      await enterReason(tester, 'Lane swap for the sun');
      await tapAndSettle(tester, keyOf('move-confirm'));

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
        find.descendant(
          of: tileOf('Ann Lee', 2),
          matching: keyOf('moved-label'),
        ),
        findsOneWidget,
      );
      expect(find.text('Moved'), findsOneWidget);
      expect(find.text('Moves'), findsOneWidget);
      expect(find.text('Round 2: Lane swap for the sun'), findsOneWidget);
    });

    testWidgets('a reason is required and the dialog stays', (tester) async {
      final server = moveServer();
      await pumpMatrixPage(tester, server);
      await openMove(tester, 'Ann Lee', 1);
      await tapAndSettle(tester, keyOf('move-confirm'));
      expect(find.text('Choose a group to move the pilot to.'), findsOneWidget);
      expect(find.text('Enter a reason.'), findsOneWidget);
      await tapAndSettle(tester, keyOf('move-group-B'));
      await tapAndSettle(tester, keyOf('move-confirm'));
      expect(find.text('Choose a group to move the pilot to.'), findsNothing);
      expect(find.text('Enter a reason.'), findsOneWidget);
      expect(server.moves, isEmpty);
    });

    testWidgets('cancel leaves the matrix as it was', (tester) async {
      final server = moveServer();
      await pumpMatrixPage(tester, server);
      await openMove(tester, 'Ann Lee', 1);
      await tapAndSettle(tester, keyOf('move-cancel'));
      expect(find.byType(AlertDialog), findsNothing);
      expect(server.moves, isEmpty);
      expect(keyOf('moved-label'), findsNothing);
    });
  });

  group('when moving is off', () {
    testWidgets('a locked contest shows Move off with the reason', (
      tester,
    ) async {
      await pumpMatrixPage(
        tester,
        moveServer(
          contest: matrixContest(
            state: LifecycleState.running,
            lock: AdminLock.locked,
          ),
        ),
      );
      await tapAndSettle(tester, tileOf('Ann Lee', 1));
      await tapAndSettle(
        tester,
        find.descendant(
          of: tileOf('Ann Lee', 1),
          matching: keyOf('pilot-actions'),
        ),
      );
      expect(
        tester.widget<PopupMenuItem<void>>(keyOf('pilot-action-move')).enabled,
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
        moveServer(contest: matrixContest(state: LifecycleState.completed)),
      );
      await tapAndSettle(tester, tileOf('Ann Lee', 1));
      await tapAndSettle(
        tester,
        find.descendant(
          of: tileOf('Ann Lee', 1),
          matching: keyOf('pilot-actions'),
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
      await pumpMatrixPage(tester, moveServer());
      expect(keyOf('pilot-actions'), findsNothing);
      await tapAndSettle(tester, tileOf('Ann Lee', 1));
      expect(keyOf('pilot-actions'), findsNWidgets(2));
    });
  });
}
