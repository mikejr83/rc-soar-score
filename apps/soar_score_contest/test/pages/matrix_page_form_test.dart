import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/new_contest/contest_draft_store.dart';
import 'package:soar_score_contest/services/new_contest/draw_settings.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/matrix_test_support.dart';

final _rounds = find.byKey(const ValueKey('draw-rounds'));
final _groups = find.byKey(const ValueKey('draw-groups'));
final _draw = find.byKey(const ValueKey('draw-button'));

MatrixServer _server({
  Contest? contest,
  int status = 200,
  String error = 'rejected',
}) => MatrixServer(
  contest: contest,
  configuration: matrixConfiguration(),
  drawStatus: status,
  drawError: error,
);

Future<void> _fill(
  WidgetTester tester, {
  String rounds = '3',
  String groups = '2',
}) async {
  await tester.enterText(_rounds, rounds);
  await tester.enterText(_groups, groups);
  await tester.pump();
}

Future<void> _confirm(WidgetTester tester) async {
  await tester.ensureVisible(_draw);
  await tester.tap(_draw);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('prefills groups and rounds from the wizard it was created in', (
    tester,
  ) async {
    final drafts = ContestDraftStore();
    drafts.drawSuggestions[contestId] = const DrawSettings(
      groups: '2',
      rounds: '5',
    );
    await pumpMatrixPage(tester, _server(), drafts: drafts);
    expect(tester.widget<TextField>(_groups).controller?.text, '2');
    expect(tester.widget<TextField>(_rounds).controller?.text, '5');
    expect(
      find.text('From the New Contest wizard: 2 groups per round'),
      findsOneWidget,
    );
    expect(find.text('2 groups: 2, 2 pilots'), findsOneWidget);
  });

  testWidgets('asks when the wizard values are gone', (tester) async {
    await pumpMatrixPage(tester, _server());
    expect(tester.widget<TextField>(_groups).controller?.text, isEmpty);
  });

  testWidgets('shows the empty state and the form with no configured value', (
    tester,
  ) async {
    await pumpMatrixPage(tester, _server());
    expect(find.text('No matrix drawn yet'), findsOneWidget);
    expect(find.text('Draw the first matrix'), findsOneWidget);
    expect(
      find.textContaining('Contest configuration has no value'),
      findsNWidgets(2),
    );
    expect(tester.widget<FilledButton>(_draw).onPressed, isNotNull);
    expect(find.text('4 scoring pilots'), findsOneWidget);
    expect(find.text('1 non-flying participant is excluded.'), findsOneWidget);
    expect(find.text('Configuration revision'), findsOneWidget);
  });

  testWidgets('shows the resulting group sizes as you type', (tester) async {
    await pumpMatrixPage(tester, _server());
    await _fill(tester, groups: '3');
    expect(find.text('3 groups: 2, 1, 1 pilots'), findsOneWidget);
    expect(
      find.textContaining('Group B would have'),
      findsNothing,
      reason: 'two groups would have 1 pilot, so the warning counts them',
    );
    expect(find.textContaining('2 groups would have 1 pilot'), findsOneWidget);
  });

  testWidgets('an empty form is only an error once Draw is pressed', (
    tester,
  ) async {
    await pumpMatrixPage(tester, _server());
    expect(find.textContaining('Enter the number of rounds'), findsNothing);
    await _confirm(tester);
    expect(find.textContaining('Enter the number of rounds'), findsWidgets);
    expect(find.text('Fix 2 fields before drawing'), findsOneWidget);
    expect(find.text('Draw the matrix?'), findsNothing);
  });

  testWidgets('the confirmation names the draw, then the matrix is shown', (
    tester,
  ) async {
    final server = _server();
    await pumpMatrixPage(tester, server);
    await _fill(tester);
    await _confirm(tester);
    expect(find.text('Draw the matrix?'), findsOneWidget);
    expect(find.text('4 scoring pilots'), findsWidgets);
    expect(find.text('3 rounds'), findsOneWidget);
    expect(find.text('2 groups per round (2, 2 pilots)'), findsOneWidget);
    expect(find.text('Configuration revision 14'), findsOneWidget);
    expect(server.draws, isEmpty);

    await tester.tap(find.byKey(const ValueKey('confirm-draw')));
    await tester.pumpAndSettle();
    expect(server.draws, hasLength(1));
    expect(server.draws.single['rounds'], 3);
    expect(server.draws.single['groups_per_round'], 2);
    expect(server.draws.single['attempts_per_round'], 50);
    expect(server.draws.single['seed_count'], 3);
    expect(server.draws.single['random_seed'], isNull);
    expect(find.text('Round 1'), findsOneWidget);
    expect(find.text('Draw the first matrix'), findsNothing);
  });

  testWidgets('cancelling the confirmation draws nothing', (tester) async {
    final server = _server();
    await pumpMatrixPage(tester, server);
    await _fill(tester);
    await _confirm(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(server.draws, isEmpty);
    expect(find.text('Draw the first matrix'), findsOneWidget);
  });

  testWidgets('a rejected draw keeps the values and says why', (tester) async {
    await pumpMatrixPage(
      tester,
      _server(status: 400, error: 'Team protection needs 4 groups.'),
    );
    await _fill(tester);
    await _confirm(tester);
    await tester.tap(find.byKey(const ValueKey('confirm-draw')));
    await tester.pumpAndSettle();
    expect(find.text('The server rejected the draw'), findsOneWidget);
    expect(
      find.textContaining('Server: Team protection needs 4 groups.'),
      findsOneWidget,
    );
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Draw the first matrix'), findsOneWidget);
  });

  testWidgets('a conflict asks for a reload and disables the draw', (
    tester,
  ) async {
    await pumpMatrixPage(tester, _server(status: 409));
    await _fill(tester);
    await _confirm(tester);
    await tester.tap(find.byKey(const ValueKey('confirm-draw')));
    await tester.pumpAndSettle();
    expect(find.text('This contest changed on the server'), findsOneWidget);
    expect(find.text('Reload the contest before drawing.'), findsOneWidget);
    expect(tester.widget<FilledButton>(_draw).onPressed, isNull);
  });

  testWidgets('a lost connection offers Try again and keeps the values', (
    tester,
  ) async {
    final server = _server();
    await pumpMatrixPage(tester, server);
    await _fill(tester);
    await _confirm(tester);
    server.offline = true;
    await tester.tap(find.byKey(const ValueKey('confirm-draw')));
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t reach the server'), findsOneWidget);
    expect(find.byKey(const ValueKey('try-again')), findsOneWidget);
    expect(find.text('Draw the first matrix'), findsOneWidget);
  });

  group('disabled form', () {
    Future<void> expectBlocked(
      WidgetTester tester,
      MatrixServer server,
      String reason,
    ) async {
      await pumpMatrixPage(tester, server);
      expect(find.text('Draw the first matrix'), findsOneWidget);
      expect(find.textContaining(reason), findsOneWidget);
      expect(tester.widget<FilledButton>(_draw).onPressed, isNull);
    }

    testWidgets('locked', (tester) async {
      await expectBlocked(
        tester,
        _server(contest: matrixContest(lock: AdminLock.locked)),
        'The contest is locked',
      );
      expect(find.text('Unlock in Configuration'), findsOneWidget);
    });

    testWidgets('completed', (tester) async {
      await expectBlocked(
        tester,
        _server(contest: matrixContest(state: LifecycleState.completed)),
        'The contest is completed',
      );
    });

    testWidgets('no configuration', (tester) async {
      await expectBlocked(
        tester,
        MatrixServer(),
        'No configuration is saved yet',
      );
      expect(find.text('Fix in Configuration'), findsOneWidget);
    });
  });
}
