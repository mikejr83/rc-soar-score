import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/controls/contest_transition.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/matrix_test_support.dart';
import '../../../support/next_step_widget_support.dart';
import '../../../support/workspace_facts_support.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

/// A running contest whose scored flights are [scored] (round, pilot).
WorkspaceServer _server(Iterable<(int, int)> scored, {int scoresStatus = 200}) {
  final matrix = drawnMatrix();
  return WorkspaceServer(
    configuration: matrixConfiguration(),
    matrix: matrix,
    scores: scoresFor(matrix, {
      for (final flight in scored) flight: at(flight.$1 * 20 + flight.$2),
    }),
    scoresStatus: scoresStatus,
  );
}

Iterable<(int, int)> _round(int round, [int pilots = 4]) => [
  for (var p = 1; p <= pilots; p++) (round, p),
];

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(_key('control-complete'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists the flights without a score', (tester) async {
    await pumpWorkspace(tester, _server([..._round(1), ..._round(2, 2)]));
    await _openDialog(tester);

    expect(_key('complete-dialog'), findsOneWidget);
    expect(find.text('Lifecycle: Running → Completed'), findsOneWidget);
    expect(
      tester.widget<Text>(_key('complete-dialog-missing')).data,
      '• 2 flights have no score',
    );
    expect(_key('complete-dialog-unflown'), findsNothing);
  });

  testWidgets('lists the rounds nobody flew', (tester) async {
    await pumpWorkspace(tester, _server(_round(1)));
    await _openDialog(tester);

    expect(
      tester.widget<Text>(_key('complete-dialog-unflown')).data,
      '• Round 2 not flown',
    );
    expect(_key('complete-dialog-missing'), findsNothing);
  });

  testWidgets('says so when nothing is open', (tester) async {
    await pumpWorkspace(tester, _server([..._round(1), ..._round(2)]));
    await _openDialog(tester);
    expect(_key('complete-dialog-clear'), findsOneWidget);
  });

  testWidgets('says the lists are missing when the scores cannot be read', (
    tester,
  ) async {
    await pumpWorkspace(tester, _server(_round(1), scoresStatus: 500));
    await _openDialog(tester);
    expect(_key('complete-dialog-unknown'), findsOneWidget);
    expect(_key('complete-dialog-missing'), findsNothing);
  });

  testWidgets('cancel leaves the contest running', (tester) async {
    final server = _server(_round(1));
    await pumpWorkspace(tester, server);
    await _openDialog(tester);
    await tester.tap(_key('complete-dialog-cancel'));
    await tester.pumpAndSettle();
    expect(server.actions, isEmpty);
    expect(server.contest.lifecycleState, LifecycleState.running);
  });

  testWidgets('confirming completes the contest and shows it at once', (
    tester,
  ) async {
    final server = _server(_round(1));
    await pumpWorkspace(tester, server);
    await _openDialog(tester);
    await tester.tap(_key('complete-dialog-confirm'));
    await tester.pumpAndSettle();

    expect(server.actions, ['complete']);
    expect(find.text(completedMessage), findsOneWidget);
    // A completed contest cannot go back, so there is no Undo.
    expect(find.text('Undo'), findsNothing);
    expect(
      tester.widget<Text>(_key('status-lifecycle-value')).data,
      'Completed',
    );
    expect(tester.widget<Text>(_key('status-scoring-value')).data, 'Closed');
    expect(
      tester.widget<FilledButton>(_key('control-complete')).onPressed,
      isNull,
    );
  });

  testWidgets('the next-step card opens the same dialog', (tester) async {
    final server = _server([..._round(1), ..._round(2)]);
    await pumpWorkspace(tester, server);
    await tester.tap(_key('next-step-primary'));
    await tester.pumpAndSettle();
    expect(_key('complete-dialog'), findsOneWidget);

    await tester.tap(_key('complete-dialog-confirm'));
    await tester.pumpAndSettle();
    expect(server.actions, ['complete']);
    expect(find.text(completedMessage), findsOneWidget);
  });

  testWidgets('a rejected completion leaves the page unchanged', (
    tester,
  ) async {
    final server = _server(_round(1))..rejectNext = 409;
    await pumpWorkspace(tester, server);
    await _openDialog(tester);
    await tester.tap(_key('complete-dialog-confirm'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining("Your change to the contest wasn't applied"),
      findsOneWidget,
    );
    expect(tester.widget<Text>(_key('status-lifecycle-value')).data, 'Running');
  });
}
