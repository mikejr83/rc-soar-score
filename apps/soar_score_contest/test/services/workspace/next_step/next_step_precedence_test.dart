import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/next_step/next_step_kind.dart';
import 'package:soar_score_contest/services/workspace/next_step/next_step_target.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/matrix_test_support.dart';
import '../../../support/next_step_support.dart';
import '../../../support/workspace_facts_support.dart';

const _seeded = {'draw_mode': 'SeededManOnMan'};

void main() {
  group('seeded contests', () {
    test('every round scored with rounds left to draw draws the next', () {
      final step = stepAt(
        stepFacts(
          state: LifecycleState.running,
          matrix: drawnMatrix(),
          scored: allScored(),
          core: {..._seeded, 'intended_total_rounds': 4},
        ),
        minutes: 100,
      );
      expect(step.kind, NextStepKind.drawNextSeededRound);
      expect(step.title, 'Draw round 3');
      expect(
        step.body,
        'Rounds 1-2 have all scores entered. Seeded rounds are drawn one at a '
        'time from the current standings.',
      );
      expect(step.primary.label, 'Go to Matrix to draw round 3');
      expect(step.primary.target, NextStepTarget.matrix);
      expect(step.primary.round, 3);
    });

    test('without an intended total there is always another round', () {
      final step = stepAt(
        stepFacts(
          state: LifecycleState.running,
          matrix: drawnMatrix(),
          scored: allScored(),
          core: _seeded,
        ),
        minutes: 100,
      );
      expect(step.kind, NextStepKind.drawNextSeededRound);
    });

    test('once the intended total is drawn and scored, complete', () {
      final step = stepAt(
        stepFacts(
          state: LifecycleState.running,
          matrix: drawnMatrix(),
          scored: allScored(),
          core: {..._seeded, 'intended_total_rounds': 2},
        ),
        minutes: 100,
      );
      expect(step.kind, NextStepKind.completeAllScores);
    });

    test('a round still being scored continues scoring', () {
      final step = stepAt(
        stepFacts(
          state: LifecycleState.running,
          matrix: drawnMatrix(),
          scored: midRoundTwo(),
          core: {..._seeded, 'intended_total_rounds': 4},
        ),
        minutes: 100,
      );
      expect(step.kind, NextStepKind.continueScoring);
    });
  });

  group('precedence', () {
    final idle = 100 + 48 * 60;

    test('complete-all-scores beats idle', () {
      final step = stepAt(
        stepFacts(
          state: LifecycleState.running,
          matrix: drawnMatrix(),
          scored: allScored(),
        ),
        minutes: idle,
      );
      expect(step.kind, NextStepKind.completeAllScores);
      expect(step.reason?.text, startsWith('every round'));
    });

    test('idle beats drawing the next seeded round', () {
      final facts = stepFacts(
        state: LifecycleState.running,
        matrix: drawnMatrix(),
        scored: allScored(),
        core: {..._seeded, 'intended_total_rounds': 4},
      );
      expect(stepAt(facts, minutes: idle).kind, NextStepKind.completeIdle);
      expect(
        stepAt(facts, minutes: 100).kind,
        NextStepKind.drawNextSeededRound,
      );
    });

    test('a cancelled round is not drawn', () {
      final step = stepAt(
        stepFacts(
          state: LifecycleState.running,
          matrix: drawnMatrix(round2Status: RoundStatus.cancelled),
          scored: {for (var p = 1; p <= 4; p++) (1, p): at(p)},
        ),
        minutes: 100,
      );
      expect(step.kind, NextStepKind.completeAllScores);
      expect(step.reason?.text, 'every round has all 4 scores (rounds 1–1).');
    });

    test('drift beats scoring being open', () {
      final step = stepAt(
        stepFacts(
          state: LifecycleState.ready,
          access: ScoringAccess.open,
          matrix: drawnMatrix(config: const {'team_protection': true}),
        ),
      );
      expect(step.kind, NextStepKind.redrawMatrix);
    });
  });

  group('dismissed suggestion', () {
    final complete = stepFacts(
      state: LifecycleState.running,
      matrix: drawnMatrix(),
      scored: allScored(),
    );

    test('becomes continue scoring', () {
      final step = stepAt(complete, minutes: 100, dismissed: true);
      expect(step.kind, NextStepKind.continueScoringAfterDismissal);
      expect(step.isSuggestion, isFalse);
      expect(step.title, 'Continue scoring');
      expect(
        step.body,
        'Nothing new to score right now. Complete the contest from Contest '
        'controls when you’re ready.',
      );
      expect(step.primary.label, 'Open Scoring');
      expect(step.primary.target, NextStepTarget.scoring);
    });

    test('also replaces the idle suggestion', () {
      final facts = stepFacts(
        state: LifecycleState.running,
        matrix: drawnMatrix(),
        scored: midRoundTwo(),
      );
      expect(
        stepAt(facts, minutes: 65 + 48 * 60, dismissed: true).kind,
        NextStepKind.continueScoringAfterDismissal,
      );
    });

    test('changes nothing for other steps', () {
      final facts = stepFacts(
        state: LifecycleState.running,
        matrix: drawnMatrix(),
        scored: midRoundTwo(),
      );
      expect(
        stepAt(facts, minutes: 100, dismissed: true).kind,
        NextStepKind.continueScoring,
      );
    });
  });
}
