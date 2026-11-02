import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/matrix_move_support.dart';
import '../support/matrix_test_support.dart';

/// The scored-pilot warning and the error paths of a move (#263).
void main() {
  group('a scored pilot', () {
    testWidgets('is warned and the button names the consequence', (
      tester,
    ) async {
      final server = moveServer();
      server.scoredAssignments.add((1, 1));
      await pumpMatrixPage(tester, server);
      await openMove(tester, 'Ann Lee', 1);

      expect(keyOf('move-score-warning'), findsOneWidget);
      expect(find.textContaining('not the standard way'), findsOneWidget);
      expect(find.text('Move pilot'), findsNothing);
      expect(find.text('Discard score and move'), findsOneWidget);

      await tapAndSettle(tester, keyOf('move-group-B'));
      await enterReason(tester, 'Scored in the wrong group');
      await tapAndSettle(tester, keyOf('move-confirm'));
      expect(server.moves, hasLength(1));
    });

    testWidgets('an unscored pilot gets no warning', (tester) async {
      await pumpMatrixPage(tester, moveServer());
      await openMove(tester, 'Ann Lee', 1);
      expect(keyOf('move-score-warning'), findsNothing);
      expect(find.text('Move pilot'), findsOneWidget);
    });
  });

  group('errors', () {
    testWidgets('a refused move keeps the dialog and the values', (
      tester,
    ) async {
      final server = moveServer()
        ..moveStatus = 409
        ..moveCode = 'team_conflict'
        ..moveError = 'a teammate already flies in this group';
      await pumpMatrixPage(tester, server);
      await openMove(tester, 'Ann Lee', 1);
      await tapAndSettle(tester, keyOf('move-group-B'));
      await enterReason(tester, 'Keep this text');
      await tapAndSettle(tester, keyOf('move-confirm'));

      expect(keyOf('move-error'), findsOneWidget);
      expect(find.textContaining('teammate'), findsWidgets);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        tester.widget<TextField>(keyOf('move-reason')).controller!.text,
        'Keep this text',
      );
      // The grid is as it was.
      expect(keyOf('moved-label'), findsNothing);

      // Trying again sends the same request id.
      server.moveStatus = 201;
      await tapAndSettle(tester, keyOf('move-confirm'));
      expect(server.moves, hasLength(2));
      expect(
        (server.moves.first['body'] as Map)['id'],
        (server.moves.last['body'] as Map)['id'],
      );
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('a stale matrix offers Reload', (tester) async {
      final server = moveServer()
        ..moveStatus = 409
        ..moveCode = 'group_locked'
        ..moveError = 'group 2 is locked';
      await pumpMatrixPage(tester, server);
      await openMove(tester, 'Ann Lee', 1);
      await tapAndSettle(tester, keyOf('move-group-B'));
      await enterReason(tester, 'x');
      await tapAndSettle(tester, keyOf('move-confirm'));

      expect(
        find.text(
          'The matrix or the contest changed since this page loaded. Nothing '
          'was moved. Reload to see the current matrix.',
        ),
        findsOneWidget,
      );
      expect(keyOf('move-confirm'), findsNothing);
      await tapAndSettle(tester, keyOf('move-reload'));
      expect(find.byType(AlertDialog), findsNothing);
      expect(keyOf('moved-label'), findsNothing);
    });

    testWidgets('a lost connection says nothing was moved', (tester) async {
      final server = moveServer();
      await pumpMatrixPage(tester, server);
      await openMove(tester, 'Ann Lee', 1);
      await tapAndSettle(tester, keyOf('move-group-B'));
      await enterReason(tester, 'x');
      server.offline = true;
      await tapAndSettle(tester, keyOf('move-confirm'));
      expect(
        find.text(
          'Soar Score can\'t reach the server. Nothing was moved. Try again.',
        ),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('scores that cannot be read stop the move', (tester) async {
      final server = moveServer()..scoresStatus = 500;
      await pumpMatrixPage(tester, server);
      await openMove(tester, 'Ann Lee', 1);
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        find.textContaining('The scores could not be checked'),
        findsOneWidget,
      );
    });
  });

  group('more refusals', () {
    testWidgets('a retired pilot cannot be moved', (tester) async {
      final server = moveServer()..retirements[1] = 2;
      await pumpMatrixPage(tester, server);
      await openMove(tester, 'Ann Lee', 1);
      expect(
        find.text('This pilot has retired and cannot be moved.'),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(keyOf('move-confirm')).onPressed,
        isNull,
      );
    });

    testWidgets('a lost connection keeps the id even if the reason changes', (
      tester,
    ) async {
      final server = moveServer();
      await pumpMatrixPage(tester, server);
      await openMove(tester, 'Ann Lee', 1);
      await tapAndSettle(tester, keyOf('move-group-B'));
      await enterReason(tester, 'first');
      server.moveStatus = 500;
      await tapAndSettle(tester, keyOf('move-confirm'));
      expect(keyOf('move-error'), findsOneWidget);
      server.moveStatus = 201;
      await enterReason(tester, 'second');
      await tapAndSettle(tester, keyOf('move-confirm'));
      expect(server.moves, hasLength(2));
      expect(
        (server.moves.first['body'] as Map)['id'],
        (server.moves.last['body'] as Map)['id'],
      );
    });
  });
}
