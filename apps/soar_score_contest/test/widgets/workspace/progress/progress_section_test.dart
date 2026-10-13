import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/matrix_test_support.dart';
import '../../../support/next_step_widget_support.dart';
import '../../../support/workspace_facts_support.dart';

WorkspaceServer _server({
  LifecycleState state = LifecycleState.running,
  Map<(int, int), DateTime>? scored,
  int scoresStatus = 200,
}) {
  final matrix = drawnMatrix();
  return WorkspaceServer(
    state: state,
    configuration: matrixConfiguration(),
    matrix: matrix,
    scores: scoresFor(matrix, scored ?? const {}),
    scoresStatus: scoresStatus,
  );
}

void main() {
  testWidgets('a running contest shows its rounds in the workspace', (
    tester,
  ) async {
    await pumpWorkspace(
      tester,
      _server(scored: {(1, 1): at(0), (1, 2): at(1), (2, 1): at(10)}),
    );

    expect(find.byKey(const ValueKey('progress-card')), findsOneWidget);
    expect(find.text('Round 2 of 2'), findsOneWidget);
    expect(find.text('2 missing'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
  });

  testWidgets('a tile opens Scoring at its round', (tester) async {
    await pumpWorkspace(
      tester,
      _server(scored: {(1, 1): at(0), (2, 1): at(10)}),
    );

    await tester.tap(find.byKey(const ValueKey('progress-tile-1')));
    await tester.pumpAndSettle();

    expect(find.text('Scoring stub'), findsOneWidget);
    final router = GoRouter.of(tester.element(find.text('Scoring stub')));
    expect(
      router.state.uri.toString(),
      contestScoringPath(matrixContestId, round: 1),
    );
  });

  testWidgets('a matrix with no scores reads as not started', (tester) async {
    await pumpWorkspace(tester, _server(state: LifecycleState.ready));

    expect(find.byKey(const ValueKey('progress-card')), findsOneWidget);
    expect(find.text('No scores yet'), findsOneWidget);
    expect(find.textContaining('matrix revision'), findsOneWidget);
  });

  testWidgets('unavailable scores leave a retry, not a blank card', (
    tester,
  ) async {
    await pumpWorkspace(tester, _server(scoresStatus: 500));

    expect(find.text('Round progress could not be loaded.'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-retry')), findsOneWidget);
  });

  testWidgets('a contest with no matrix has no progress card', (tester) async {
    await pumpWorkspace(
      tester,
      WorkspaceServer(
        state: LifecycleState.configuring,
        configuration: matrixConfiguration(),
      ),
    );

    expect(find.byKey(const ValueKey('progress-card')), findsNothing);
  });

  testWidgets('a completed contest keeps the card, read-only', (tester) async {
    await pumpWorkspace(
      tester,
      _server(
        state: LifecycleState.completed,
        scored: {
          for (var r = 1; r <= 2; r++)
            for (var p = 1; p <= 4; p++) (r, p): at(r * 10 + p),
        },
      ),
    );

    expect(find.byKey(const ValueKey('progress-card')), findsOneWidget);
    expect(find.text('Final'), findsOneWidget);
    expect(find.text('All 2 rounds flown'), findsOneWidget);
  });
}
