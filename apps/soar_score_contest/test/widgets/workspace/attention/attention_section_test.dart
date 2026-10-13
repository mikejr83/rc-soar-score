import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/matrix_test_support.dart';
import '../../../support/next_step_widget_support.dart';
import '../../../support/workspace_facts_support.dart';

WorkspaceServer _server(
  Map<(int, int), DateTime> scored, {
  LifecycleState state = LifecycleState.running,
  int scoresStatus = 200,
}) {
  final matrix = drawnMatrix();
  return WorkspaceServer(
    state: state,
    configuration: matrixConfiguration(),
    matrix: matrix,
    scores: scoresFor(matrix, scored),
    scoresStatus: scoresStatus,
  );
}

void main() {
  testWidgets('a running contest lists the missing scores', (tester) async {
    await pumpWorkspace(
      tester,
      _server({(1, 1): at(0), (1, 2): at(1), (2, 1): at(10)}),
    );

    expect(find.byKey(const ValueKey('attention-card')), findsOneWidget);
    expect(find.text('2 scores missing in finished round'), findsOneWidget);
    expect(find.text('Round 1: 2'), findsOneWidget);
  });

  testWidgets('the link opens Scoring at the first round with gaps', (
    tester,
  ) async {
    await pumpWorkspace(
      tester,
      _server({(1, 1): at(0), (1, 2): at(1), (2, 1): at(10)}),
    );

    await tester.tap(
      find.byKey(const ValueKey('attention-link-missingScores')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Scoring stub'), findsOneWidget);
    final router = GoRouter.of(tester.element(find.text('Scoring stub')));
    expect(
      router.state.uri.toString(),
      contestScoringPath(matrixContestId, round: 1),
    );
  });

  testWidgets('a running contest with nothing missing is all clear', (
    tester,
  ) async {
    await pumpWorkspace(tester, _server({(1, 1): at(0)}));

    expect(find.text('Nothing needs attention'), findsOneWidget);
  });

  testWidgets('unavailable scores do not read as all clear', (tester) async {
    await pumpWorkspace(tester, _server(const {}, scoresStatus: 500));

    expect(find.text('Nothing needs attention'), findsNothing);
    expect(
      find.text('Needs attention could not be worked out'),
      findsOneWidget,
    );
  });

  testWidgets('a completed contest hides the card when nothing is missing', (
    tester,
  ) async {
    await pumpWorkspace(
      tester,
      _server({
        for (var r = 1; r <= 2; r++)
          for (var p = 1; p <= 4; p++) (r, p): at(r * 10 + p),
      }, state: LifecycleState.completed),
    );

    expect(find.byKey(const ValueKey('attention-card')), findsNothing);
    expect(find.byKey(const ValueKey('progress-card')), findsOneWidget);
  });

  testWidgets('a completed contest shows the card when scores are missing', (
    tester,
  ) async {
    await pumpWorkspace(
      tester,
      _server({
        (1, 1): at(0),
        (1, 2): at(1),
        (1, 3): at(2),
        (1, 4): at(3),
        (2, 1): at(10),
      }, state: LifecycleState.completed),
    );

    expect(find.byKey(const ValueKey('attention-card')), findsOneWidget);
    expect(find.text('3 scores missing in finished round'), findsOneWidget);
  });

  testWidgets('before running the list is not on the page', (tester) async {
    await pumpWorkspace(tester, _server(const {}, state: LifecycleState.ready));

    expect(find.byKey(const ValueKey('attention-card')), findsNothing);
  });
}
