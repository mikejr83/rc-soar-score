import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/card_columns.dart';
import 'package:soar_score_contest/services/reports/pilot_cards/pilot_cards_data.dart';
import 'package:soar_score_contest/services/workspace/workspace_facts.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/matrix_test_support.dart';
import '../support/workspace_facts_support.dart';

/// [slot] as a participant's waiting submission: Submitted (or InReview),
/// no official score, the values on the pending attempt.
ScoreSlot _pending(
  ScoreSlot slot, {
  bool inReview = false,
  Map<String, Object?> components = const {
    'time_flown': 540,
    'launch_height': 120,
  },
}) {
  final placeholder = ScorePlaceholder(
    id: slot.placeholder.id,
    contestId: contestId,
    contestParticipationId: slot.placeholder.contestParticipationId,
    assignmentId: slot.placeholder.assignmentId,
    state: inReview
        ? ScorePlaceholderState.inReview
        : ScorePlaceholderState.submitted,
  );
  return ScoreSlot(
    placeholder: placeholder,
    pendingAttempt: ScoreAttempt(
      id: Id.create(),
      contestId: contestId,
      scorePlaceholderId: placeholder.id,
      configRevisionId: Id.create(),
      matrixRevisionId: Id.create(),
      rawComponents: components,
      actorId: Id.create(),
      authority: Authority.participant,
      clientMutationId: 'pending',
      baseScoreRevision: 0,
      acceptedAt: DateTime.utc(2026, 10, 17, 15),
    ),
  );
}

void main() {
  test('pilot cards print a waiting submission as not official', () {
    final matrix = drawnMatrix();
    final slot = scoreSlot(matrix.assignments.first);
    final score = PilotCardsData.scoreOf(_pending(slot), const {});
    expect(score, isNotNull);
    expect(score!.official, isFalse);
    expect(score.text[CardField.time], '9:00');
    expect(score.text[CardField.height], '120');
  });

  test('a review never prints values without a submission', () {
    final slot = scoreSlot(drawnMatrix().assignments.first);
    final inReview = ScoreSlot(
      placeholder: _pending(slot, inReview: true).placeholder,
    );
    expect(PilotCardsData.scoreOf(inReview, const {}), isNull);
    expect(PilotCardsData.scoreOf(slot, const {}), isNull);
  });

  test('the workspace counts waiting submissions as scores', () {
    final matrix = drawnMatrix();
    final base = scoresFor(matrix, {(1, 1): at(0)});
    final slots = [
      for (final s in base.slots)
        s.officialScore == null &&
                s.placeholder.assignmentId == matrix.assignments[1].id
            ? _pending(s)
            : s,
    ];
    final facts = WorkspaceFacts.derive(
      data: workspaceData(matrix: matrix),
      scores: ContestScores(slots: slots, rounds: base.rounds),
    );
    expect(facts.scoreCount, 2);
  });
}
