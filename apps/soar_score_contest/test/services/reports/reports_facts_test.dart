import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/reports_facts.dart';
import 'package:soar_score_contest/services/workspace/workspace_facts.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../support/matrix_test_support.dart';
import '../../support/workspace_facts_support.dart';

Map<(int, int), DateTime> _scored({int minuteOffset = 0}) => {
  for (var r = 1; r <= 2; r++)
    for (var p = 1; p <= 4; p++) (r, p): at(r * 10 + p + minuteOffset),
};

ReportsFacts _facts(ContestScores scores, CurrentMatrix matrix) {
  final data = workspaceData(matrix: matrix);
  return ReportsFacts.derive(
    data: data,
    scores: scores,
    workspace: WorkspaceFacts.derive(data: data, scores: scores),
  );
}

void main() {
  group('fingerprint', () {
    final matrix = drawnMatrix();

    test('is the same for the same data', () {
      final a = _facts(scoresFor(matrix, _scored()), matrix);
      final b = _facts(scoresFor(matrix, _scored()), matrix);
      expect(a.fingerprint, b.fingerprint);
    });

    test('changes when a score is corrected but the counts do not', () {
      final before = _facts(scoresFor(matrix, _scored()), matrix);
      // Every slot stays scored and official; only when one was set differs.
      final scored = _scored()..[(1, 2)] = at(500);
      final after = _facts(scoresFor(matrix, scored), matrix);

      expect(after.fullyScoredRounds, before.fullyScoredRounds);
      expect(after.progressText, before.progressText);
      expect(after.resultStatus, before.resultStatus);
      expect(after.fingerprint, isNot(before.fingerprint));
    });

    test('changes when a score moves to another revision', () {
      final base = scoresFor(matrix, _scored());
      final slot = base.slots.first;
      final revised = ContestScores(
        rounds: base.rounds,
        slots: [
          ScoreSlot(
            placeholder: slot.placeholder,
            officialScore: OfficialScore(
              id: slot.officialScore!.id,
              contestId: slot.officialScore!.contestId,
              scorePlaceholderId: slot.officialScore!.scorePlaceholderId,
              scoreAttemptId: slot.officialScore!.scoreAttemptId,
              scoreRevision: slot.officialScore!.scoreRevision + 1,
              components: const {},
              setAt: slot.officialScore!.setAt,
              setBy: slot.officialScore!.setBy,
              reason: 'Corrected',
            ),
          ),
          ...base.slots.skip(1),
        ],
      );
      expect(
        _facts(revised, matrix).fingerprint,
        isNot(_facts(base, matrix).fingerprint),
      );
    });

    test('changes when a score is added', () {
      final fewer = _scored()..remove((2, 4));
      expect(
        _facts(scoresFor(matrix, _scored()), matrix).fingerprint,
        isNot(_facts(scoresFor(matrix, fewer), matrix).fingerprint),
      );
    });
  });

  test('carries the matrix and configuration revisions', () {
    final matrix = drawnMatrix();
    final facts = _facts(scoresFor(matrix, const {}), matrix);
    expect(facts.matrixRevision, 1);
    expect(facts.configurationRevision, 14);

    final none = ReportsFacts.derive(
      data: workspaceData(withConfiguration: false),
      scores: ContestScores(),
      workspace: WorkspaceFacts.derive(
        data: workspaceData(withConfiguration: false),
        scores: ContestScores(),
      ),
    );
    expect(none.matrixRevision, isNull);
    expect(none.configurationRevision, isNull);
  });
}
