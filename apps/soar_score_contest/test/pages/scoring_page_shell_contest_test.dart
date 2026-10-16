import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/widgets/contest_scope.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/matrix_test_support.dart';
import '../support/scoring_test_support.dart';

Future<void> _saveFirstRow(WidgetTester tester) async {
  final id = scoringAssignmentId(1, 1).value;
  await tester.tap(find.byKey(ValueKey('score-row-$id')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(ValueKey('score-time-$id')), '630');
  await tester.enterText(find.byKey(ValueKey('score-height-$id')), '180');
  await tester.pump();
  await tester.tap(find.byKey(ValueKey('score-landing-$id-within_1m')));
  await tester.pump();
  await tester.tap(find.byKey(ValueKey('score-save-$id')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the first saved score reloads the shell contest', (
    tester,
  ) async {
    var reloads = 0;
    final server = ScoringServer(
      contest: matrixContest(state: LifecycleState.ready),
    );
    await pumpScoringPage(
      tester,
      server,
      round: 1,
      group: 1,
      shell: ContestScope(
        contest: matrixContest(state: LifecycleState.ready),
        reload: () async {
          reloads++;
          return true;
        },
        child: const SizedBox(),
      ),
    );
    expect(reloads, 0);

    await _saveFirstRow(tester);

    expect(server.entries, hasLength(1));
    expect(reloads, 1);
  });

  testWidgets('a score in a Running contest does not reload the shell', (
    tester,
  ) async {
    var reloads = 0;
    final server = ScoringServer();
    await pumpScoringPage(
      tester,
      server,
      round: 1,
      group: 1,
      shell: ContestScope(
        contest: matrixContest(state: LifecycleState.running),
        reload: () async {
          reloads++;
          return true;
        },
        child: const SizedBox(),
      ),
    );
    await _saveFirstRow(tester);

    expect(server.entries, hasLength(1));
    expect(reloads, 0);
  });
}
