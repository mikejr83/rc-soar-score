import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/csv_export/score_export_options.dart';
import 'package:soar_score_contest/services/reports/reports_facts.dart';
import 'package:soar_score_contest/services/reports/result_status.dart';
import 'package:soar_score_contest/services/reports/standings/standings_options.dart';
import 'package:soar_score_contest/services/workspace/workspace_facts.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../support/matrix_test_support.dart';
import '../../support/standings_fixtures.dart';
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
  test('a pending-only last round keeps standings at the prior snapshot', () {
    final fixture = StandingsFixture(
      trailingScore: ScorePlaceholderState.submitted,
    );
    final facts = factsOf(fixture, state: LifecycleState.completed);

    expect(facts.lastScoredRound, 2);
    expect(facts.lastStoredStandingsRound, 1);
    expect(facts.resultStatus, ResultStatus.preliminary);
    expect(facts.standing.missingByRound, {2: 3});
    expect(facts.standing.unofficialByRound, {2: 1});
    expect(StandingsOptions.of(const {}, facts).requestedTo, 1);
    expect(ScoreExportOptions.of(const {}, facts).requestedTo, 1);
  });

  test('recalculation at the same round changes the refresh fingerprint', () {
    final fixture = StandingsFixture(
      trailingScore: ScorePlaceholderState.official,
    )..setStandingsStale(2, true);
    final before = factsOf(fixture, state: LifecycleState.completed);
    fixture.setStandingsStale(2, false);
    final after = factsOf(fixture, state: LifecycleState.completed);

    expect(before.lastStoredStandingsRound, after.lastStoredStandingsRound);
    expect(before.standing.missingByRound, after.standing.missingByRound);
    expect(before.resultStatus, ResultStatus.preliminary);
    expect(after.resultStatus, ResultStatus.official);
    expect(before.fingerprint, isNot(after.fingerprint));
  });

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

    test('changes when a waiting submission is replaced by a newer one', () {
      final base = scoresFor(matrix, const {});
      ScoreSlot waiting(ScoreSlot slot, String attempt) => ScoreSlot(
        placeholder: ScorePlaceholder(
          id: slot.placeholder.id,
          contestId: slot.placeholder.contestId,
          contestParticipationId: slot.placeholder.contestParticipationId,
          assignmentId: slot.placeholder.assignmentId,
          state: ScorePlaceholderState.submitted,
        ),
        pendingAttempt: ScoreAttempt(
          id: Id.parse(attempt),
          contestId: slot.placeholder.contestId,
          scorePlaceholderId: slot.placeholder.id,
          configRevisionId: Id.create(),
          matrixRevisionId: Id.create(),
          rawComponents: const {'time_flown': 500},
          actorId: Id.create(),
          authority: Authority.participant,
          clientMutationId: attempt,
          baseScoreRevision: 0,
          acceptedAt: at(1),
        ),
      );
      ContestScores with_(String attempt) => ContestScores(
        rounds: base.rounds,
        slots: [waiting(base.slots.first, attempt), ...base.slots.skip(1)],
      );
      final a = Id.create().value;
      final b = Id.create().value;
      expect(
        _facts(with_(a), matrix).fingerprint,
        isNot(_facts(with_(b), matrix).fingerprint),
      );
      expect(
        _facts(with_(a), matrix).fingerprint,
        _facts(with_(a), matrix).fingerprint,
      );
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
