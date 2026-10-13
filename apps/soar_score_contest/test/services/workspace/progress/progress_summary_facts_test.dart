import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/progress/progress_headline.dart';
import 'package:soar_score_contest/services/workspace/progress/progress_summary.dart';
import 'package:soar_score_contest/services/workspace/progress/progress_tile.dart';
import 'package:soar_score_contest/services/workspace/workspace_fact_source.dart';
import 'package:soar_score_contest/services/workspace/workspace_facts.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/matrix_test_support.dart';
import '../../../support/workspace_facts_support.dart';

void main() {
  test('no matrix gives the no-matrix headline and no tiles', () {
    final summary = ProgressSummary.of(
      WorkspaceFacts.derive(data: workspaceData()),
    );
    expect(summary.headline.stage, ProgressStage.noMatrix);
    expect(summary.tiles, isEmpty);
  });

  test('a drawn matrix with no scores reads from the facts', () {
    final matrix = drawnMatrix();
    final summary = ProgressSummary.of(
      WorkspaceFacts.derive(
        data: workspaceData(matrix: matrix),
        scores: scoresFor(matrix, const {}),
      ),
    );
    expect(summary.headline.stage, ProgressStage.noScores);
    expect(summary.headline.roundCount, 2);
    expect(summary.headline.groupCount, 2);
    expect(summary.tiles.map((t) => t.state), [
      ProgressTileState.notFlown,
      ProgressTileState.notFlown,
    ]);
  });

  test('a failed scores read is unavailable, not empty', () {
    final matrix = drawnMatrix();
    final summary = ProgressSummary.of(
      WorkspaceFacts.derive(
        data: workspaceData(matrix: matrix),
        unavailable: {WorkspaceFactSource.scores},
      ),
    );
    expect(summary.headline.stage, ProgressStage.scoresUnavailable);
  });

  test('round 2 in progress with a gap in round 1', () {
    final matrix = drawnMatrix();
    final summary = ProgressSummary.of(
      WorkspaceFacts.derive(
        data: workspaceData(matrix: matrix),
        scores: scoresFor(matrix, {
          (1, 1): at(0),
          (1, 2): at(1),
          (1, 3): at(2),
          (2, 1): at(10),
        }),
      ),
    );
    expect(summary.tiles.map((t) => t.state), [
      ProgressTileState.missing,
      ProgressTileState.inProgress,
    ]);
    expect(summary.missingTotal, 1);
    expect(summary.headline.currentRound, 2);
    expect(summary.headline.currentGroup, 1);
    expect(summary.headline.scoreCount, 4);
    expect(summary.lag!.pending, 1);
  });

  test('correcting an earlier round does not move the frontier', () {
    final matrix = drawnMatrix();
    final facts = WorkspaceFacts.derive(
      data: workspaceData(matrix: matrix),
      scores: scoresFor(matrix, {
        (1, 1): at(0),
        (1, 2): at(1),
        (2, 1): at(5),
        // Round 1 group 2 was entered last, after round 2 had started.
        (1, 3): at(9),
      }),
    );
    // The next-step facts follow the latest score by time...
    expect(facts.currentGroup!.roundOrdinal, 1);
    expect(facts.latestScore!.setAt, at(9));

    final headline = ProgressSummary.of(facts).headline;
    // ...while the progress card stays on the latest round with a score.
    expect(headline.currentRound, 2);
    expect(headline.currentGroup, 1);
    expect(headline.latestScoreAt, at(9));
  });

  test('a completed contest reads as finished', () {
    final matrix = drawnMatrix();
    final facts = WorkspaceFacts.derive(
      data: workspaceData(state: LifecycleState.completed, matrix: matrix),
      scores: scoresFor(matrix, {
        for (var r = 1; r <= 2; r++)
          for (var p = 1; p <= 4; p++) (r, p): at(r * 10 + p),
      }),
    );
    final summary = ProgressSummary.of(facts);
    expect(summary.headline.stage, ProgressStage.finished);
    expect(summary.headline.allRoundsFlown, isTrue);
    expect(summary.headline.scoreCount, 8);
    expect(summary.missingRounds, isEmpty);
  });
}
