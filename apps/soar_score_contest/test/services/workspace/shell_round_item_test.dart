import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/shell_round_item.dart';
import 'package:soar_score_contest/services/workspace/workspace_fact_source.dart';
import 'package:soar_score_contest/services/workspace/workspace_facts.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../support/matrix_test_support.dart';
import '../../support/workspace_facts_support.dart';

void main() {
  test('a draft contest has no round item', () {
    final matrix = drawnMatrix();
    for (final state in [LifecycleState.created, LifecycleState.configuring]) {
      final facts = WorkspaceFacts.derive(
        data: workspaceData(state: state, matrix: matrix),
        scores: scoresFor(matrix, const {}),
      );
      expect(ShellRoundItem.of(facts), isNull, reason: state.name);
    }
  });

  test('no matrix has no round item', () {
    final facts = WorkspaceFacts.derive(
      data: workspaceData(state: LifecycleState.ready),
    );
    expect(ShellRoundItem.of(facts), isNull);
  });

  test('unreadable scores have no round item', () {
    final matrix = drawnMatrix();
    final facts = WorkspaceFacts.derive(
      data: workspaceData(matrix: matrix),
      unavailable: {WorkspaceFactSource.scores},
    );
    expect(ShellRoundItem.of(facts), isNull);
  });

  test('a drawn contest with no scores is not started', () {
    final matrix = drawnMatrix();
    final facts = WorkspaceFacts.derive(
      data: workspaceData(state: LifecycleState.ready, matrix: matrix),
      scores: scoresFor(matrix, const {}),
    );
    expect(ShellRoundItem.of(facts)!.kind, ShellRoundKind.notStarted);
  });

  test('scoring in progress names the round and group', () {
    final matrix = drawnMatrix();
    final facts = WorkspaceFacts.derive(
      data: workspaceData(matrix: matrix),
      scores: scoresFor(matrix, {
        (1, 1): at(0),
        (1, 2): at(1),
        (1, 3): at(2),
        (2, 1): at(10),
      }),
    );
    final item = ShellRoundItem.of(facts)!;
    expect(item.kind, ShellRoundKind.inProgress);
    expect(item.round, 2);
    expect(item.total, 2);
    expect(item.group, 1);
    expect(item.groupLetter, 'A');
  });

  test('a completed contest is finished', () {
    final matrix = drawnMatrix();
    final facts = WorkspaceFacts.derive(
      data: workspaceData(state: LifecycleState.completed, matrix: matrix),
      scores: scoresFor(matrix, {
        for (var r = 1; r <= 2; r++)
          for (var p = 1; p <= 4; p++) (r, p): at(r * 10 + p),
      }),
    );
    expect(ShellRoundItem.of(facts)!.kind, ShellRoundKind.finished);
  });
}
