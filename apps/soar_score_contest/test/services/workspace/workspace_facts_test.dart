import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/matrix/round_progress_view.dart';
import 'package:soar_score_contest/services/workspace/publication_facts.dart';
import 'package:soar_score_contest/services/workspace/workspace_facts.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../support/matrix_test_support.dart';
import '../../support/workspace_facts_support.dart';

void main() {
  group('without a matrix', () {
    final facts = WorkspaceFacts.derive(data: workspaceData());

    test('counts pilots and reports an empty matrix', () {
      expect(facts.scoringPilots, 4);
      expect(facts.hasMatrix, isFalse);
      expect(facts.roundCount, 0);
      expect(facts.groupCount, 0);
      expect(facts.groupSizeMin, 0);
      expect(facts.latestScore, isNull);
      expect(facts.currentGroup, isNull);
      expect(facts.configDrift, isEmpty);
      expect(facts.rounds, isEmpty);
      expect(facts.onlyPilotName, isNull);
    });

    test('has no audit facts until the trail supplies them', () {
      expect(facts.completedAt, isNull);
      expect(facts.lockedAt, isNull);
      expect(facts.lockedBy, isNull);
    });
  });

  test('names the only pilot', () {
    final facts = WorkspaceFacts.derive(
      data: workspaceData(
        participations: [
          matrixParticipations().first,
          matrixParticipations().last,
        ],
      ),
    );
    expect(facts.scoringPilots, 1);
    expect(facts.onlyPilotName, 'Ann Lee');
  });

  test('reports configuration problems and draw blockers', () {
    final none = WorkspaceFacts.derive(
      data: workspaceData(withConfiguration: false),
    );
    expect(none.configurationProblem, contains('No configuration'));
    expect(none.drawReadiness.enabled, isFalse);

    final bad = WorkspaceFacts.derive(
      data: workspaceData(core: const {'draw_mode': 'nonsense'}),
    );
    expect(bad.options, isNull);
    expect(bad.configurationProblem, contains('not valid'));
  });

  test('a drawn matrix has rounds, groups and group sizes', () {
    final facts = WorkspaceFacts.derive(
      data: workspaceData(matrix: drawnMatrix()),
    );
    expect(facts.hasMatrix, isTrue);
    expect(facts.roundCount, 2);
    expect(facts.groupCount, 2);
    expect(facts.groupSizeMin, 2);
    expect(facts.groupSizeMax, 2);
    expect(facts.drawReadiness.enabled, isFalse, reason: 'already drawn');
  });

  group('scores', () {
    test('a matrix with no scores has no latest score', () {
      final matrix = drawnMatrix();
      final facts = WorkspaceFacts.derive(
        data: workspaceData(matrix: matrix),
        scores: scoresFor(matrix, const {}),
      );
      expect(facts.latestScore, isNull);
      expect(facts.currentGroup, isNull);
      expect(
        facts.rounds.map((r) => r.state),
        everyElement(RoundProgressState.notFlown),
      );
    });

    test('scores in the middle of round 2 find the group and what is next', () {
      final matrix = drawnMatrix();
      final facts = WorkspaceFacts.derive(
        data: workspaceData(matrix: matrix),
        scores: scoresFor(matrix, {
          (1, 1): at(0),
          (1, 2): at(1),
          (1, 3): at(2),
          (1, 4): at(3),
          (2, 1): at(10),
          (2, 3): at(12),
        }),
      );
      expect(facts.latestScore?.roundOrdinal, 2);
      expect(facts.latestScore?.groupNumber, 1);
      expect(facts.latestScore?.setAt, at(12));
      final group = facts.currentGroup!;
      expect((group.scored, group.total), (2, 2));
      expect(group.isComplete, isTrue);
      expect((group.nextRoundOrdinal, group.nextGroupNumber), (2, 2));
      expect(facts.rounds.map((r) => r.state), [
        RoundProgressState.scored,
        RoundProgressState.inProgress,
      ]);
      expect((facts.rounds.last.scored, facts.rounds.last.total), (2, 4));
    });

    test('the last group of a round points to group 1 of the next round', () {
      final matrix = drawnMatrix();
      final facts = WorkspaceFacts.derive(
        data: workspaceData(matrix: matrix),
        scores: scoresFor(matrix, {(1, 3): at(5)}),
      );
      final group = facts.currentGroup!;
      expect((group.roundOrdinal, group.groupNumber), (1, 2));
      expect((group.scored, group.total), (1, 2));
      expect((group.nextRoundOrdinal, group.nextGroupNumber), (2, 1));
    });

    test('when every round is complete nothing flies next', () {
      final matrix = drawnMatrix();
      final facts = WorkspaceFacts.derive(
        data: workspaceData(matrix: matrix),
        scores: scoresFor(matrix, {
          for (var r = 1; r <= 2; r++)
            for (var p = 1; p <= 4; p++) (r, p): at(r * 10 + p),
        }),
      );
      expect(facts.currentGroup!.nextRoundOrdinal, isNull);
      expect(facts.currentGroup!.nextGroupNumber, isNull);
      expect(
        facts.rounds.map((r) => r.state),
        everyElement(RoundProgressState.scored),
      );
    });

    test('a cancelled round is left out', () {
      final matrix = drawnMatrix(round2Status: RoundStatus.cancelled);
      final facts = WorkspaceFacts.derive(
        data: workspaceData(matrix: matrix),
        scores: scoresFor(matrix, {(1, 1): at(0)}),
      );
      expect(facts.roundCount, 1);
      expect(facts.rounds.map((r) => r.ordinal), [1]);
    });

    test('a superseded assignment is ignored', () {
      final plain = drawnMatrix();
      final old = plain.assignments.firstWhere(
        (a) => a.contestParticipationId == participationId(1),
      );
      final moved = moveAssignment(plain, old, 2);
      final facts = WorkspaceFacts.derive(
        data: workspaceData(matrix: moved),
        scores: scoresFor(moved, {(1, 2): at(1)}),
      );
      // Pilot 2 was scored in round 1 group 1 {1,2}; pilot 1 moved out, so
      // the group now holds one pilot and group 2 holds three.
      expect(facts.groupSizeMin, 1);
      expect(facts.groupSizeMax, 3);
      expect(facts.currentGroup!.total, 1);
    });

    test('a late-added pilot raises a round total above the pilot count', () {
      final matrix = drawnMatrix();
      final scores = scoresFor(matrix, {(1, 1): at(0)});
      final widened = ContestScores(
        slots: scores.slots,
        rounds: [
          RoundProgress(
            roundId: scores.rounds.first.roundId,
            ordinal: 1,
            scored: 1,
            total: 5,
          ),
          scores.rounds.last,
        ],
      );
      final facts = WorkspaceFacts.derive(
        data: workspaceData(matrix: matrix),
        scores: widened,
      );
      expect(facts.rounds.first.total, 5);
      expect(facts.scoringPilots, 4);
    });

    test('unavailable scores leave the rest of the facts', () {
      final matrix = drawnMatrix();
      final facts = WorkspaceFacts.derive(data: workspaceData(matrix: matrix));
      expect(facts.rounds, isEmpty);
      expect(facts.latestScore, isNull);
      expect(facts.roundCount, 2);
    });
  });

  group('configuration drift', () {
    test('is empty when nothing differs', () {
      final facts = WorkspaceFacts.derive(
        data: workspaceData(matrix: drawnMatrix()),
      );
      expect(facts.configDrift, isEmpty);
    });

    test('lists settings that differ from the draw', () {
      final facts = WorkspaceFacts.derive(
        data: workspaceData(
          matrix: drawnMatrix(config: const {'team_protection': true}),
        ),
      );
      expect(facts.configDrift, [
        'Team protection is now Off (drawn with On).',
      ]);
    });
  });

  group('publication', () {
    test('is unknown unless told', () {
      expect(
        WorkspaceFacts.derive(data: workspaceData()).publication,
        PublicationFacts.unknown,
      );
    });

    test('is parsed defensively', () {
      final public = PublicationFacts.fromJson(const {
        'visibility': 'Public',
        'published_at': '2026-10-18T12:00:00.000Z',
      });
      expect(public.isPublished, isTrue);
      expect(public.visibility, PublicationVisibility.public);
      expect(public.publishedAt, DateTime.utc(2026, 10, 18, 12));
      expect(
        PublicationFacts.fromJson(const {'visibility': 'Unlisted'}).publishedAt,
        isNull,
      );
      expect(
        PublicationFacts.fromJson(const {'visibility': 'Delisted'}).visibility,
        PublicationVisibility.delisted,
      );
      expect(PublicationFacts.fromJson(const {}), PublicationFacts.unknown);
      expect(
        PublicationFacts.fromJson(const {'visibility': 7}),
        PublicationFacts.unknown,
      );
    });
  });
}
