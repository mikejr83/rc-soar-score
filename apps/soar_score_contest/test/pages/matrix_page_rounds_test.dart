import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/matrix/matrix_rounds_plan.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/matrix_test_support.dart';

/// Adding rounds and redrawing the unscored rounds (#264).
MatrixServer _server({
  (int, int)? scored,
  Contest? contest,
  Map<String, Object?>? drawn,
  RoundStatus round2Status = RoundStatus.open,
  Map<String, Object?> core = const {},
}) => MatrixServer(
  contest: contest ?? matrixContest(state: LifecycleState.ready),
  configuration: matrixConfiguration(core),
  matrix: drawnMatrix(
    scored: scored,
    config: drawn,
    round2Status: round2Status,
  ),
);

final _add = find.byKey(const ValueKey('add-rounds'));
final _redraw = find.byKey(const ValueKey('redraw-rounds'));
final _submit = find.byKey(const ValueKey('draw-button'));
final _confirm = find.byKey(const ValueKey('confirm-rounds'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _inDialog(String text) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

String _text(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.byKey(ValueKey(key))).controller!.text;

void main() {
  group('add rounds', () {
    testWidgets(
      'the form is prefilled and the new rounds continue the matrix',
      (tester) async {
        final server = _server();
        await pumpMatrixPage(tester, server);
        await _tap(tester, _add);

        expect(find.text('Add rounds'), findsWidgets);
        expect(_text(tester, 'draw-rounds'), '1');
        expect(_text(tester, 'draw-groups'), '2');
        expect(find.text('Draws round 3.'), findsOneWidget);

        await tester.enterText(find.byKey(const ValueKey('draw-rounds')), '2');
        await tester.pump();
        expect(find.text('Draws rounds 3 to 4.'), findsOneWidget);

        await _tap(tester, _submit);
        expect(_inDialog('Add rounds?'), findsOneWidget);
        expect(_inDialog('Adds rounds 3 to 4'), findsOneWidget);
        expect(_inDialog('Current matrix revision 1'), findsOneWidget);
        await _tap(tester, _confirm);

        expect(server.redraws, hasLength(1));
        expect(server.redraws.single['first_round'], 3);
        expect(server.redraws.single['rounds'], 2);
        expect(server.redraws.single['groups_per_round'], 2);
        expect(server.redraws.single['random_seed'], isNull);
        expect(find.text('Rounds added.'), findsOneWidget);
        // Back on the matrix.
        expect(_add, findsOneWidget);
        expect(find.byKey(const ValueKey('back-to-matrix')), findsNothing);
      },
    );

    testWidgets('the button in the grid opens the same form', (tester) async {
      await pumpMatrixPage(tester, _server());
      await _tap(tester, find.byKey(const ValueKey('grid-add-rounds')));
      expect(find.byKey(const ValueKey('draw-rounds')), findsOneWidget);
      expect(find.text('Rounds to add'), findsOneWidget);
    });

    testWidgets('is allowed while rounds have scores', (tester) async {
      final server = _server(scored: (4, 4));
      await pumpMatrixPage(tester, server);
      await _tap(tester, _add);
      await _tap(tester, _submit);
      await _tap(tester, _confirm);
      expect(server.redraws.single['first_round'], 3);
    });
  });

  group('redraw unscored rounds', () {
    testWidgets('with nothing scored it replaces the whole matrix with a '
        'fresh seed and the reason', (tester) async {
      final server = _server();
      await pumpMatrixPage(tester, server);
      await _tap(tester, _redraw);

      expect(
        find.textContaining('Replaces the unscored rounds 1 to 2.'),
        findsOneWidget,
      );
      expect(_text(tester, 'draw-rounds'), '2');
      expect(_text(tester, 'draw-groups'), '2');

      await tester.enterText(
        find.byKey(const ValueKey('draw-reason')),
        'Did not like the first draw',
      );
      await _tap(tester, _submit);
      expect(_inDialog('Redraw unscored rounds?'), findsOneWidget);
      expect(_inDialog('Redraws rounds 1 to 2'), findsOneWidget);
      await _tap(tester, _confirm);

      final body = server.redraws.single;
      expect(body['first_round'], 1);
      expect(body['rounds'], 2);
      expect(body['groups_per_round'], 2);
      expect(body['random_seed'], isNull);
      expect(body['reason'], 'Did not like the first draw');
      expect(find.text('Rounds redrawn.'), findsOneWidget);

      // A second redraw is a new request with its own id.
      final firstId = body['id'];
      await _tap(tester, _redraw);
      await _tap(tester, _submit);
      await _tap(tester, _confirm);
      expect(server.redraws, hasLength(2));
      expect(server.redraws.last['id'], isNot(firstId));
    });

    testWidgets('starts at the first unscored round and says so', (
      tester,
    ) async {
      final server = _server(scored: (4, 0));
      await pumpMatrixPage(tester, server);
      await _tap(tester, _redraw);

      expect(
        find.textContaining('Replaces the unscored round 2.'),
        findsOneWidget,
      );
      expect(_text(tester, 'draw-rounds'), '1');
      await _tap(tester, _submit);
      await _tap(tester, _confirm);
      expect(server.redraws.single['first_round'], 2);
    });

    testWidgets('is off, with the reason beside it, when every round has '
        'scores', (tester) async {
      await pumpMatrixPage(tester, _server(scored: (4, 4)));
      expect(tester.widget<OutlinedButton>(_redraw).onPressed, isNull);
      expect(
        find.text('Every round has scores, so there is nothing to redraw.'),
        findsOneWidget,
      );
      expect(tester.widget<OutlinedButton>(_add).onPressed, isNotNull);
    });

    testWidgets('is off when a round to replace is locked', (tester) async {
      await pumpMatrixPage(
        tester,
        _server(scored: (4, 0), round2Status: RoundStatus.locked),
      );
      expect(tester.widget<OutlinedButton>(_redraw).onPressed, isNull);
      expect(
        find.text('Round 2 is locked. Unlock it before redrawing.'),
        findsOneWidget,
      );
    });

    testWidgets('both actions are off while administration is locked', (
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
      expect(tester.widget<OutlinedButton>(_redraw).onPressed, isNull);
      expect(tester.widget<OutlinedButton>(_add).onPressed, isNull);
      expect(
        find.text(
          'Administration is locked. Unlock the contest to add or redraw '
          'rounds.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a rejection keeps the form and the matrix', (tester) async {
      final server = _server()
        ..redrawStatus = 400
        ..redrawCode = 'invalid'
        ..redrawError =
            'round 1 already has scores; only rounds without '
            'scores can be redrawn';
      await pumpMatrixPage(tester, server);
      await _tap(tester, _redraw);
      await tester.enterText(find.byKey(const ValueKey('draw-rounds')), '3');
      await _tap(tester, _submit);
      await _tap(tester, _confirm);

      expect(find.text('The server did not change the matrix'), findsOneWidget);
      expect(find.textContaining('already has scores'), findsWidgets);
      expect(_text(tester, 'draw-rounds'), '3');
      expect(find.byKey(const ValueKey('reload')), findsNothing);

      // Back leaves the matrix as it was.
      await _tap(tester, find.byKey(const ValueKey('back-to-matrix')));
      expect(find.text('Round 2'), findsOneWidget);
      expect(_redraw, findsOneWidget);
    });

    testWidgets('scores that arrived meanwhile ask for a reload', (
      tester,
    ) async {
      final server = _server()
        ..redrawStatus = 409
        ..redrawCode = 'rounds_have_scores';
      await pumpMatrixPage(tester, server);
      await _tap(tester, _redraw);
      await _tap(tester, _submit);
      await _tap(tester, _confirm);
      expect(find.byKey(const ValueKey('reload')), findsOneWidget);
      expect(_text(tester, 'draw-rounds'), '2');
    });

    testWidgets('a stale matrix asks for a reload and keeps the values', (
      tester,
    ) async {
      final server = _server()
        ..redrawStatus = 409
        ..redrawCode = 'stale_matrix'
        ..redrawError = 'the matrix has changed';
      await pumpMatrixPage(tester, server);
      await _tap(tester, _redraw);
      await _tap(tester, _submit);
      await _tap(tester, _confirm);
      expect(find.byKey(const ValueKey('reload')), findsOneWidget);
      expect(_text(tester, 'draw-rounds'), '2');
    });

    testWidgets('a lost connection keeps the form and offers to try again', (
      tester,
    ) async {
      final server = _server();
      await pumpMatrixPage(tester, server);
      await _tap(tester, _redraw);
      server.offline = true;
      await _tap(tester, _submit);
      await _tap(tester, _confirm);
      expect(find.text('Couldn’t reach the server'), findsOneWidget);
      expect(_text(tester, 'draw-rounds'), '2');
      expect(find.byKey(const ValueKey('try-again')), findsOneWidget);
    });

    testWidgets('the form checks the groups like the first draw', (
      tester,
    ) async {
      final server = _server();
      await pumpMatrixPage(tester, server);
      await _tap(tester, _redraw);
      await tester.enterText(find.byKey(const ValueKey('draw-groups')), '9');
      await _tap(tester, _submit);
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        find.textContaining('There are only 4 scoring pilots'),
        findsWidgets,
      );
      expect(server.redraws, isEmpty);
    });
  });

  group('configuration changed banner', () {
    testWidgets('offers the redraw of the unscored rounds', (tester) async {
      final server = _server(
        drawn: const {'team_protection': true, 'lane_mode': 'None'},
      );
      await pumpMatrixPage(tester, server);
      await _tap(tester, find.byKey(const ValueKey('banner-redraw')));
      expect(find.byKey(const ValueKey('draw-rounds')), findsOneWidget);
      expect(find.text('Rounds to draw'), findsOneWidget);
    });

    testWidgets('says why when no redraw is possible', (tester) async {
      await pumpMatrixPage(
        tester,
        _server(
          scored: (4, 4),
          drawn: const {'team_protection': true, 'lane_mode': 'None'},
        ),
      );
      expect(find.byKey(const ValueKey('banner-redraw')), findsNothing);
      expect(find.textContaining('Every round has scores'), findsWidgets);
    });
  });

  testWidgets('the next-step link opens the form straight away', (
    tester,
  ) async {
    await pumpMatrixPage(tester, _server(), intent: MatrixIntent.redraw);
    expect(find.byKey(const ValueKey('draw-rounds')), findsOneWidget);
    expect(find.text('Rounds to draw'), findsOneWidget);
  });

  testWidgets('a link to a redraw that is not allowed shows the matrix', (
    tester,
  ) async {
    await pumpMatrixPage(
      tester,
      _server(scored: (4, 4)),
      intent: MatrixIntent.redraw,
    );
    expect(find.byKey(const ValueKey('draw-rounds')), findsNothing);
    expect(
      find.text('Every round has scores, so there is nothing to redraw.'),
      findsOneWidget,
    );
  });

  testWidgets('the placeholders for later releases are gone', (tester) async {
    await pumpMatrixPage(tester, _server());
    expect(
      find.byTooltip('Round actions (redraw) · later release'),
      findsNothing,
    );
    expect(find.textContaining('later release'), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  group('seeded contests', () {
    testWidgets('show the preliminary rounds and what is missing', (
      tester,
    ) async {
      await pumpMatrixPage(
        tester,
        _server(
          scored: (4, 1),
          core: const {'draw_mode': 'SeededManOnMan', 'preliminary_rounds': 2},
        ),
      );
      expect(
        find.textContaining('2 preliminary rounds, 3 flights still need'),
        findsOneWidget,
      );
    });

    testWidgets('seeded rounds are drawn one at a time', (tester) async {
      final server = _server(
        scored: (4, 4),
        core: const {'draw_mode': 'SeededManOnMan', 'preliminary_rounds': 2},
      );
      await pumpMatrixPage(tester, server);
      await _tap(tester, _add);
      expect(_text(tester, 'draw-rounds'), '1');
      await tester.enterText(find.byKey(const ValueKey('draw-rounds')), '2');
      await _tap(tester, _submit);
      expect(find.text('Seeded rounds are drawn one at a time.'), findsWidgets);
      expect(server.redraws, isEmpty);
    });
  });
}
