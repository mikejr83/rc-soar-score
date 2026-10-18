import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/report_availability.dart';
import 'package:soar_score_contest/services/reports/report_kind.dart';
import 'package:soar_score_contest/services/reports/reports_facts.dart';
import 'package:soar_score_contest/services/reports/result_status.dart';
import 'package:soar_score_contest/services/workspace/workspace_facts.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../support/matrix_test_support.dart';
import '../../support/workspace_facts_support.dart';

ReportsFacts _facts({
  CurrentMatrix? matrix,
  Map<(int, int), DateTime>? scored,
  Map<String, Object?> core = const {},
  LifecycleState state = LifecycleState.running,
  ScorePlaceholderState? slotState,
}) {
  final data = workspaceData(state: state, matrix: matrix, core: core);
  var scores = scored == null || matrix == null
      ? ContestScores()
      : scoresFor(matrix, scored);
  if (slotState != null) {
    final first = scores.slots.firstWhere((s) => s.officialScore != null);
    scores = ContestScores(
      rounds: scores.rounds,
      slots: [
        for (final slot in scores.slots)
          slot == first
              ? ScoreSlot(
                  placeholder: ScorePlaceholder(
                    id: slot.placeholder.id,
                    contestId: slot.placeholder.contestId,
                    contestParticipationId:
                        slot.placeholder.contestParticipationId,
                    assignmentId: slot.placeholder.assignmentId,
                    state: slotState,
                  ),
                  officialScore: slot.officialScore,
                )
              : slot,
      ],
    );
  }
  return ReportsFacts.derive(
    data: data,
    scores: scores,
    workspace: WorkspaceFacts.derive(data: data, scores: scores),
  );
}

Map<(int, int), DateTime> _all(int rounds) => {
  for (var r = 1; r <= rounds; r++)
    for (var p = 1; p <= 4; p++) (r, p): at(r * 10 + p),
};

void main() {
  group('without a matrix', () {
    final facts = _facts();

    test('every report is unavailable and points to what is missing', () {
      final standings = ReportAvailability.of(ReportKind.standings, facts);
      expect(standings.isAvailable, isFalse);
      expect(standings.reason, 'No scores have been entered yet.');
      for (final kind in ReportKind.values.where((k) => !k.needsScores)) {
        final availability = ReportAvailability.of(kind, facts);
        expect(availability.isAvailable, isFalse, reason: kind.title);
        expect(availability.reason, 'The matrix has not been drawn.');
        expect(availability.action!.destination, ReportDestination.matrix);
      }
    });

    test('there are no standings and no progress', () {
      expect(facts.resultStatus, ResultStatus.none);
      expect(facts.progressText, 'No rounds scored');
    });
  });

  group('with a matrix and no scores', () {
    final facts = _facts(matrix: drawnMatrix(), scored: const {});

    test('standings point to scoring; the documents are available', () {
      final standings = ReportAvailability.of(ReportKind.standings, facts);
      expect(standings.isAvailable, isFalse);
      expect(standings.reason, 'No scores have been entered yet.');
      expect(standings.action!.destination, ReportDestination.scoring);
      for (final kind in [
        ReportKind.matrix,
        ReportKind.sheet,
        ReportKind.cards,
      ]) {
        final availability = ReportAvailability.of(kind, facts);
        expect(availability.isAvailable, isTrue, reason: kind.title);
        expect(availability.notes, isEmpty);
      }
    });

    test('progress says nothing is scored and both rounds are unflown', () {
      expect(facts.progressText, 'No rounds scored · 2 not flown');
      expect(facts.resultStatus, ResultStatus.none);
    });
  });

  group('result status', () {
    test('is official when every round up to the last scored is official', () {
      final facts = _facts(matrix: drawnMatrix(), scored: _all(2));
      expect(facts.resultStatus, ResultStatus.official);
      expect(facts.progressText, '2 of 2 rounds fully scored');
      expect(ReportAvailability.of(ReportKind.standings, facts).notes, isEmpty);
    });

    test('rounds that are not flown do not make it preliminary', () {
      final facts = _facts(matrix: drawnMatrix(), scored: _round1());
      expect(facts.resultStatus, ResultStatus.official);
      expect(facts.progressText, '1 of 2 rounds fully scored · 1 not flown');
    });

    test('a missing score makes it preliminary and names the round', () {
      final scored = _all(2)..remove((2, 3));
      scored.remove((2, 4));
      final facts = _facts(matrix: drawnMatrix(), scored: scored);
      expect(facts.resultStatus, ResultStatus.preliminary);
      expect(facts.progressText, contains('1 round partly scored'));
      final note = ReportAvailability.of(
        ReportKind.standings,
        facts,
      ).notes.single;
      expect(note.lead, 'Preliminary:');
      expect(note.text, '2 pilots have no score in round 2.');
      expect(note.action!.round, 2);
    });

    test('a score that is submitted or in review makes it preliminary', () {
      for (final state in [
        ScorePlaceholderState.submitted,
        ScorePlaceholderState.inReview,
      ]) {
        final facts = _facts(
          matrix: drawnMatrix(),
          scored: _all(2),
          slotState: state,
        );
        expect(facts.resultStatus, ResultStatus.preliminary);
        final note = ReportAvailability.of(
          ReportKind.standings,
          facts,
        ).notes.single;
        expect(note.text, '1 score is not official yet.');
      }
    });
  });

  group('warnings on the documents', () {
    test('a configuration that differs from the draw is flagged', () {
      final facts = _facts(
        matrix: drawnMatrix(config: const {'team_protection': true}),
        scored: const {},
      );
      expect(facts.configDrift, isNotEmpty);
      for (final kind in [
        ReportKind.matrix,
        ReportKind.sheet,
        ReportKind.cards,
      ]) {
        final note = ReportAvailability.of(kind, facts).notes.single;
        expect(note.lead, 'Configuration changed');
        expect(note.text, contains('This report shows the drawn matrix.'));
      }
      expect(ReportAvailability.of(ReportKind.standings, facts).notes, isEmpty);
    });

    test('a seeded contest with undrawn rounds says which', () {
      final facts = _facts(
        matrix: drawnMatrix(),
        scored: const {},
        core: const {
          'draw_mode': 'SeededManOnMan',
          'preliminary_rounds': 2,
          'intended_total_rounds': 4,
        },
      );
      final note = ReportAvailability.of(ReportKind.cards, facts).notes.single;
      expect(note.lead, 'Rounds 1 to 2 drawn.');
      expect(
        note.text,
        'Rounds 3 and 4 are not drawn yet. Cards for a redrawn round must '
        'be reprinted.',
      );
    });

    test('a completed contest keeps every report available', () {
      final facts = _facts(
        matrix: drawnMatrix(),
        scored: _all(2),
        state: LifecycleState.completed,
      );
      expect(facts.isCompleted, isTrue);
      for (final kind in ReportKind.values) {
        expect(ReportAvailability.of(kind, facts).isAvailable, isTrue);
      }
    });
  });
}

Map<(int, int), DateTime> _round1() => {
  for (var p = 1; p <= 4; p++) (1, p): at(p),
};
