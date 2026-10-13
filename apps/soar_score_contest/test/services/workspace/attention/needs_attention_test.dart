import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/attention/attention_item.dart';
import 'package:soar_score_contest/services/workspace/attention/attention_source.dart';
import 'package:soar_score_contest/services/workspace/attention/needs_attention.dart';
import 'package:soar_score_contest/services/workspace/workspace_fact_source.dart';
import 'package:soar_score_contest/services/workspace/workspace_facts.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/matrix_test_support.dart';
import '../../../support/workspace_facts_support.dart';

class _Fixed implements AttentionSource {
  const _Fixed(this.result);

  final AttentionResult result;

  @override
  AttentionResult read(WorkspaceFacts facts) => result;
}

WorkspaceFacts _facts(
  Map<(int, int), DateTime> scored, {
  LifecycleState state = LifecycleState.running,
}) {
  final matrix = drawnMatrix();
  return WorkspaceFacts.derive(
    data: workspaceData(state: state, matrix: matrix),
    scores: scoresFor(matrix, scored),
  );
}

void main() {
  test('a contest without a matrix is all clear', () {
    final attention = NeedsAttention.of(
      WorkspaceFacts.derive(data: workspaceData()),
    );
    expect(attention.items, isEmpty);
    expect(attention.isAllClear, isTrue);
    expect(attention.summary, 'All clear');
  });

  test('nothing missing is all clear', () {
    final attention = NeedsAttention.of(
      _facts({
        for (var r = 1; r <= 2; r++)
          for (var p = 1; p <= 4; p++) (r, p): at(r * 10 + p),
      }),
    );
    expect(attention.hasItems, isFalse);
    expect(attention.isAllClear, isTrue);
  });

  test('the round being scored is not missing, only finished rounds are', () {
    final attention = NeedsAttention.of(
      _facts({(1, 1): at(0), (1, 2): at(1), (1, 3): at(2), (1, 4): at(3)}),
    );
    expect(attention.isAllClear, isTrue);
  });

  test('a gap in a finished round is one row with the round detail', () {
    final attention = NeedsAttention.of(
      _facts({(1, 1): at(0), (1, 2): at(1), (1, 3): at(2), (2, 1): at(10)}),
    );

    expect(attention.items, hasLength(1));
    final item = attention.items.single;
    expect(item.kind, AttentionKind.missingScores);
    expect(item.count, 1);
    expect(item.title, '1 score missing in finished round');
    expect(item.detail, 'Round 1: 1');
    expect(item.scoringRound, 1);
    expect(attention.summary, '1 item');
  });

  test('a round never flown behind the frontier is folded into the row', () {
    final matrix = drawnMatrix();
    final facts = WorkspaceFacts.derive(
      data: workspaceData(matrix: matrix),
      scores: scoresFor(matrix, {(2, 1): at(10)}),
    );

    final item = NeedsAttention.of(facts).items.single;
    expect(item.count, 4);
    expect(item.title, '4 scores missing in finished round');
    expect(item.detail, 'Round 1: 4');
  });

  test('unavailable scores are not an all-clear', () {
    final matrix = drawnMatrix();
    final attention = NeedsAttention.of(
      WorkspaceFacts.derive(
        data: workspaceData(matrix: matrix),
        unavailable: {WorkspaceFactSource.scores},
      ),
    );

    expect(attention.items, isEmpty);
    expect(attention.complete, isFalse);
    expect(attention.isAllClear, isFalse);
    expect(attention.summary, 'Not available');
  });

  test('a completed contest keeps its gaps in the last scored round', () {
    final attention = NeedsAttention.of(
      _facts({
        (1, 1): at(0),
        (1, 2): at(1),
        (1, 3): at(2),
        (1, 4): at(3),
        (2, 1): at(10),
      }, state: LifecycleState.completed),
    );

    expect(attention.items.single.detail, 'Round 2: 3');
  });

  group('more sources', () {
    const extra = AttentionItem(
      kind: AttentionKind.reviewRequests,
      count: 2,
      title: '2 review requests open',
      detail: 'Pilot 1, round 2',
      linkLabel: 'Open in Scoring',
      scoringRound: 2,
    );

    test('rows follow the order of the sources', () {
      final attention = NeedsAttention.of(
        _facts({(1, 1): at(0), (2, 1): at(10)}),
        sources: [
          const _Fixed(AttentionResult(items: [extra])),
          ...NeedsAttention.defaultSources,
        ],
      );
      expect(attention.items.map((i) => i.kind), [
        AttentionKind.reviewRequests,
        AttentionKind.missingScores,
      ]);
      expect(attention.summary, '2 items');
    });

    test('one source that cannot be read makes the list incomplete', () {
      final attention = NeedsAttention.of(
        _facts({(1, 1): at(0), (2, 1): at(10)}),
        sources: [
          const _Fixed(AttentionResult.unavailable()),
          ...NeedsAttention.defaultSources,
        ],
      );
      expect(attention.hasItems, isTrue);
      expect(attention.complete, isFalse);
    });
  });
}
