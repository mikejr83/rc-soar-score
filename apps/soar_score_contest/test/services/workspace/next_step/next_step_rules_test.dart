import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/next_step/next_step_action.dart';
import 'package:soar_score_contest/services/workspace/next_step/next_step_kind.dart';
import 'package:soar_score_contest/services/workspace/next_step/next_step_reason.dart';
import 'package:soar_score_contest/services/workspace/next_step/next_step_target.dart';
import 'package:soar_score_contest/services/workspace/next_step/next_step_tone.dart';
import 'package:soar_score_contest/services/workspace/publication_facts.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/matrix_test_support.dart';
import '../../../support/next_step_support.dart';
import '../../../support/workspace_facts_support.dart';

void main() {
  group('before a matrix', () {
    test('a created contest finishes its configuration', () {
      final step = stepAt(
        stepFacts(state: LifecycleState.created, withConfiguration: false),
      );
      expect(step.kind, NextStepKind.finishConfiguration);
      expect(step.eyebrow, 'NEXT STEP');
      expect(step.title, 'Finish the configuration');
      expect(
        step.body,
        'No configuration is saved yet, so the matrix can’t be drawn.',
      );
      expect(step.primary.label, 'Open Configuration');
      expect(step.primary.target, NextStepTarget.configuration);
      expect(step.secondary, isNull);
      expect(step.note, isNull);
      expect(step.reason, isNull);
    });

    test('a created contest with a saved configuration and 4 pilots', () {
      final step = stepAt(stepFacts(state: LifecycleState.created));
      expect(step.kind, NextStepKind.finishConfiguration);
      expect(
        step.body,
        'The contest has its details and 4 pilots from the wizard. Choose the '
        'scoring options on the Configuration page and save them.',
      );
    });

    test('with no pilots the body leaves them out', () {
      final step = stepAt(
        stepFacts(state: LifecycleState.created, participations: const []),
      );
      expect(
        step.body,
        'The contest has its details. Choose the scoring options on the '
        'Configuration page and save them.',
      );
    });

    test('a configuration problem replaces the body', () {
      final step = stepAt(stepFacts(core: const {'draw_mode': 'nonsense'}));
      expect(step.kind, NextStepKind.finishConfiguration);
      expect(
        step.body,
        'The saved configuration is not valid, so the matrix can’t be drawn.',
      );
    });

    test('one pilot asks for another, naming the pilot', () {
      final step = stepAt(
        stepFacts(
          participations: [
            matrixParticipations().first,
            matrixParticipations().last,
          ],
        ),
      );
      expect(step.kind, NextStepKind.addPilots);
      expect(step.title, 'Add at least 2 scoring pilots');
      expect(
        step.body,
        'Only 1 scoring pilot so far (Ann Lee). The matrix needs at least 2 to '
        'draw groups.',
      );
      expect(step.primary.label, 'Open Participants');
      expect(step.primary.target, NextStepTarget.participants);
    });

    test('no pilots', () {
      final step = stepAt(stepFacts(participations: const []));
      expect(step.kind, NextStepKind.addPilots);
      expect(
        step.body,
        'No scoring pilots yet. The matrix needs at least 2 to draw groups.',
      );
    });

    test('a valid configuration and two pilots draw the matrix', () {
      final step = stepAt(stepFacts());
      expect(step.kind, NextStepKind.drawMatrix);
      expect(step.title, 'Draw the matrix');
      expect(
        step.body,
        'Configuration revision 14 is saved and valid, and 4 scoring pilots '
        'are in. The draw happens on the Matrix page.',
      );
      expect(step.primary.label, 'Go to Matrix');
      expect(step.primary.target, NextStepTarget.matrix);
    });
  });

  group('with a matrix, before scoring', () {
    test('drift asks for a redraw', () {
      final step = stepAt(
        stepFacts(
          state: LifecycleState.ready,
          matrix: drawnMatrix(config: const {'team_protection': true}),
        ),
      );
      expect(step.kind, NextStepKind.redrawMatrix);
      expect(step.title, 'Redraw the matrix');
      expect(
        step.body,
        'The configuration has changed after the matrix was drawn. This '
        'change requires a new draw.',
      );
      expect(
        step.reason,
        const NextStepReason(
          lead: 'Changed since the draw:',
          text: 'Team protection is now Off (drawn with On).',
          tone: NextStepTone.warning,
        ),
      );
      expect(step.primary.target, NextStepTarget.matrix);
    });

    test('scoring closed starts scoring', () {
      final step = stepAt(
        stepFacts(state: LifecycleState.ready, matrix: drawnMatrix()),
      );
      expect(step.kind, NextStepKind.startScoring);
      expect(step.title, 'Start scoring');
      expect(
        step.body,
        'Matrix is drawn: 2 rounds, 2 groups of 2. Enter scores or open online '
        'scoring. Contest moves to running after the first score is entered.',
      );
      expect(step.primary.label, 'Open online scoring');
      expect(step.primary.target, NextStepTarget.openScoring);
      expect(
        step.secondary,
        const NextStepAction(
          label: 'Enter scores',
          target: NextStepTarget.scoring,
          round: 1,
          group: 1,
        ),
      );
    });

    test('scoring open enters scores', () {
      final step = stepAt(
        stepFacts(
          state: LifecycleState.ready,
          access: ScoringAccess.open,
          matrix: drawnMatrix(),
        ),
      );
      expect(step.kind, NextStepKind.enterScores);
      expect(step.title, 'Enter scores for round 1, group A');
      expect(
        step.body,
        'Participant scoring is open. The contest moves to Running when the '
        'first score is accepted.',
      );
      expect(step.primary.label, 'Open Scoring at round 1, group A');
      expect(step.primary.round, 1);
      expect(step.primary.group, 1);
    });

    test(
      'a configuring contest with a matrix and no drift is ready to score',
      () {
        final step = stepAt(stepFacts(matrix: drawnMatrix()));
        expect(step.kind, NextStepKind.startScoring);
      },
    );

    test('mixed group sizes read as a range', () {
      final plain = drawnMatrix();
      final moved = moveAssignment(plain, plain.assignments.first, 2);
      final step = stepAt(
        stepFacts(state: LifecycleState.ready, matrix: moved),
      );
      expect(
        step.body,
        startsWith('Matrix is drawn: 2 rounds, 2 groups of 1–3.'),
      );
    });
  });

  group('while running', () {
    test(
      'continue scoring names the group, its progress and the next group',
      () {
        final matrix = drawnMatrix();
        final step = stepAt(
          stepFacts(
            state: LifecycleState.running,
            matrix: matrix,
            scored: midRoundTwo(),
          ),
          minutes: 100,
        );
        expect(step.kind, NextStepKind.continueScoring);
        expect(step.title, 'Continue scoring: round 2, group A');
        expect(step.body, 'Group A has 2 of 2 scores in. Group B flies next.');
        expect(step.primary.label, 'Open Scoring at round 2, group A');
        expect(step.primary.target, NextStepTarget.scoring);
        expect((step.primary.round, step.primary.group), (2, 1));
      },
    );

    test('the last group of the last round has no next group', () {
      final matrix = drawnMatrix();
      final step = stepAt(
        stepFacts(
          state: LifecycleState.running,
          matrix: matrix,
          scored: {for (var p = 1; p <= 4; p++) (1, p): at(p), (2, 2): at(50)},
        ),
        minutes: 100,
      );
      expect(step.title, 'Continue scoring: round 2, group B');
      expect(step.body, 'Group B has 1 of 2 scores in.');
    });

    test('without scores it falls back to round 1, group A', () {
      final step = stepAt(
        stepFacts(state: LifecycleState.running, matrix: drawnMatrix()),
      );
      expect(step.kind, NextStepKind.continueScoring);
      expect(step.title, 'Continue scoring: round 1, group A');
      expect(step.body, 'Open Scoring to continue.');
    });

    test('every score in suggests completing', () {
      final step = stepAt(
        stepFacts(
          state: LifecycleState.running,
          matrix: drawnMatrix(),
          scored: allScored(),
        ),
        minutes: 100,
      );
      expect(step.kind, NextStepKind.completeAllScores);
      expect(step.isSuggestion, isTrue);
      expect(step.eyebrow, 'SUGGESTED NEXT STEP');
      expect(step.title, 'Complete the contest');
      expect(
        step.body,
        'You decide when the contest is over. Nothing changes until you '
        'confirm.',
      );
      expect(
        step.reason,
        const NextStepReason(
          lead: 'Why now:',
          text: 'every round has all 4 scores (rounds 1–2).',
          tone: NextStepTone.positive,
        ),
      );
      expect(step.primary.label, 'Complete contest…');
      expect(step.primary.target, NextStepTarget.completeDialog);
      expect(step.secondary?.label, 'Not yet');
      expect(step.secondary?.target, NextStepTarget.dismissSuggestion);
    });

    test('rounds with different totals say "all its scores"', () {
      final matrix = drawnMatrix();
      final even = scoresFor(matrix, allScored());
      final uneven = ContestScores(
        slots: even.slots,
        rounds: [
          for (final round in even.rounds)
            RoundProgress(
              roundId: round.roundId,
              ordinal: round.ordinal,
              scored: round.ordinal == 1 ? 5 : 4,
              total: round.ordinal == 1 ? 5 : 4,
            ),
        ],
      );
      final step = stepAt(
        stepFacts(
          state: LifecycleState.running,
          matrix: matrix,
          scores: uneven,
        ),
        minutes: 100,
      );
      expect(step.kind, NextStepKind.completeAllScores);
      expect(step.reason?.text, 'every round has all its scores (rounds 1–2).');
    });

    test('48 hours without a score suggests completing', () {
      final facts = stepFacts(
        state: LifecycleState.running,
        matrix: drawnMatrix(),
        scored: midRoundTwo(),
      );
      final step = stepAt(facts, minutes: 65 + 48 * 60);
      expect(step.kind, NextStepKind.completeIdle);
      expect(step.isSuggestion, isTrue);
      expect(
        step.reason,
        const NextStepReason(
          lead: 'Why now:',
          text:
              'no new scores for 48 hours. The last was accepted Sat Oct 17, '
              '09:05.',
          tone: NextStepTone.info,
        ),
      );
      expect(
        stepAt(facts, minutes: 65 + 48 * 60 - 1).kind,
        NextStepKind.continueScoring,
      );
    });
  });

  group('after completion', () {
    test('unpublished results are published', () {
      final step = stepAt(
        stepFacts(
          state: LifecycleState.completed,
          publication: PublicationFacts.notPublished,
        ),
      );
      expect(step.kind, NextStepKind.publishResults);
      expect(step.title, 'Publish results');
      expect(
        step.body,
        'The contest is completed. Results aren’t on the public site yet. '
        'Publishing first checks participants against the global pilot list.',
      );
      expect(step.primary.label, 'Publish results…');
      expect(step.primary.target, NextStepTarget.publish);
      expect(step.primary.enabled, isTrue);
    });

    test('publishing is disabled offline', () {
      final step = stepAt(
        stepFacts(
          state: LifecycleState.completed,
          publication: PublicationFacts.notPublished,
          offline: true,
        ),
      );
      expect(step.primary.enabled, isFalse);
      expect(step.primary.disabledNote, 'Needs a connection.');
    });

    test('published results lead to the reports', () {
      final step = stepAt(
        stepFacts(
          state: LifecycleState.completed,
          publication: PublicationFacts.fromJson(const {
            'visibility': 'Unlisted',
            'published_at': '2026-10-18T22:40:00.000Z',
          }),
        ),
      );
      expect(step.kind, NextStepKind.viewReports);
      expect(step.title, 'View reports');
      expect(
        step.body,
        'Results were published Sun Oct 18, 16:40 and are unlisted. Score '
        'corrections update the public site under the public update policy.',
      );
      expect(step.primary.label, 'Open Reports');
      expect(step.primary.target, NextStepTarget.reports);
    });

    test('published without a date', () {
      final step = stepAt(
        stepFacts(
          state: LifecycleState.completed,
          publication: PublicationFacts.fromJson(const {
            'visibility': 'Public',
          }),
        ),
      );
      expect(
        step.body,
        'Results were published and are public. Score corrections update the '
        'public site under the public update policy.',
      );
    });

    test('an unknown publication still offers the reports', () {
      final step = stepAt(stepFacts(state: LifecycleState.completed));
      expect(step.kind, NextStepKind.viewReports);
      expect(
        step.body,
        'Publication status can’t be loaded right now. Reports are available.',
      );
    });

    test('unsupported publishing offers the reports, not publishing', () {
      final step = stepAt(
        stepFacts(
          state: LifecycleState.completed,
          publication: PublicationFacts.unsupported,
        ),
      );
      expect(step.kind, NextStepKind.viewReports);
      expect(
        step.body,
        'Publishing is not available on this server. Reports are available.',
      );
      expect(step.primary.target, NextStepTarget.reports);
    });
  });
}
