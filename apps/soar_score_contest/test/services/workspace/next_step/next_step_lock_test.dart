import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/next_step/next_step_kind.dart';
import 'package:soar_score_contest/services/workspace/next_step/next_step_reason.dart';
import 'package:soar_score_contest/services/workspace/next_step/next_step_target.dart';
import 'package:soar_score_contest/services/workspace/next_step/next_step_tone.dart';
import 'package:soar_score_contest/services/workspace/publication_facts.dart';
import 'package:soar_score_contest/services/workspace/transition_facts.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/matrix_test_support.dart';
import '../../../support/next_step_support.dart';

const _locked = AdminLock.locked;
const _blocked = NextStepReason(
  lead: 'Blocked:',
  text: 'administration is locked.',
  tone: NextStepTone.blocked,
);

void main() {
  void expectUnlock(
    dynamic step, {
    required String title,
    required String body,
    required String note,
  }) {
    expect(step.kind, NextStepKind.unlock);
    expect(step.title, title);
    expect(step.body, body);
    expect(step.reason, _blocked);
    expect(step.primary.label, 'Unlock administration');
    expect(step.primary.target, NextStepTarget.unlock);
    expect(step.primary.busyLabel, 'Unlocking…');
    expect(step.secondary, isNull);
    expect(step.note, note);
  }

  test('the unlock card says who locked administration and when', () {
    final step = stepAt(
      stepFacts(
        lock: _locked,
        transitions: TransitionFacts(
          lockedAt: DateTime.utc(2026, 10, 18, 15),
          lockedBy: 'you',
        ),
      ),
    );

    expect(step.kind, NextStepKind.unlock);
    expect(
      step.reason,
      const NextStepReason(
        lead: 'Blocked:',
        text: 'administration locked by you at Sun Oct 18, 09:00.',
        tone: NextStepTone.blocked,
      ),
    );
  });

  test('the unlock card leaves out an actor the trail does not name', () {
    final step = stepAt(
      stepFacts(
        lock: _locked,
        transitions: TransitionFacts(lockedAt: DateTime.utc(2026, 10, 18, 15)),
      ),
    );

    expect(step.reason?.text, 'administration locked at Sun Oct 18, 09:00.');
  });

  test('a locked contest that needs its configuration finished', () {
    expectUnlock(
      stepAt(
        stepFacts(
          state: LifecycleState.created,
          lock: _locked,
          withConfiguration: false,
        ),
      ),
      title: 'Finish the configuration',
      body:
          'No configuration is saved yet, so the matrix can’t be drawn. '
          'Administration is locked, so the configuration can’t change until '
          'you unlock it.',
      note: 'Then open Configuration.',
    );
  });

  test('a locked contest that needs pilots', () {
    expectUnlock(
      stepAt(stepFacts(lock: _locked, participations: const [])),
      title: 'Add at least 2 scoring pilots',
      body:
          'No scoring pilots yet. Administration is locked, so participants '
          'can’t change until you unlock it.',
      note: 'Then open Participants.',
    );
  });

  test('a locked contest that needs a draw', () {
    expectUnlock(
      stepAt(stepFacts(lock: _locked)),
      title: 'Draw the matrix',
      body:
          'Configuration revision 14 is saved and valid, and 4 scoring pilots '
          'are in. Administration is locked, so the matrix can’t change until '
          'you unlock it.',
      note: 'Then go to Matrix.',
    );
  });

  test('a locked contest that needs a redraw', () {
    expectUnlock(
      stepAt(
        stepFacts(
          state: LifecycleState.ready,
          lock: _locked,
          matrix: drawnMatrix(config: const {'team_protection': true}),
        ),
      ),
      title: 'Redraw the matrix',
      body:
          'The configuration has changed after the matrix was drawn. '
          'Administration is locked, so the matrix can’t change until you '
          'unlock it.',
      note: 'Then go to Matrix.',
    );
  });

  test('a locked contest that would start scoring', () {
    expectUnlock(
      stepAt(
        stepFacts(
          state: LifecycleState.ready,
          lock: _locked,
          matrix: drawnMatrix(),
        ),
      ),
      title: 'Start scoring',
      body:
          'Matrix is drawn: 2 rounds, 2 groups of 2. Administration is locked, '
          'so scores can’t be entered until you unlock it.',
      note: 'Then open online scoring.',
    );
  });

  test('a locked contest with scoring open', () {
    expectUnlock(
      stepAt(
        stepFacts(
          state: LifecycleState.ready,
          lock: _locked,
          access: ScoringAccess.open,
          matrix: drawnMatrix(),
        ),
      ),
      title: 'Enter scores for round 1, group A',
      body:
          'Participant scoring is open. Administration is locked, so scores '
          'can’t be entered until you unlock it.',
      note: 'Then open Scoring at round 1, group A.',
    );
  });

  test('a locked contest in the middle of a round', () {
    expectUnlock(
      stepAt(
        stepFacts(
          state: LifecycleState.running,
          lock: _locked,
          matrix: drawnMatrix(),
          scored: midRoundTwo(),
        ),
        minutes: 100,
      ),
      title: 'Continue scoring: round 2, group A',
      body:
          'Group A has 2 of 2 scores in. Administration is locked, so scores '
          'can’t be entered until you unlock it.',
      note: 'Then open Scoring at round 2, group A.',
    );
  });

  test('a locked contest that needs the next seeded round', () {
    expectUnlock(
      stepAt(
        stepFacts(
          state: LifecycleState.running,
          lock: _locked,
          matrix: drawnMatrix(),
          scored: allScored(),
          core: const {
            'draw_mode': 'SeededManOnMan',
            'intended_total_rounds': 4,
          },
        ),
        minutes: 100,
      ),
      title: 'Draw round 3',
      body:
          'Rounds 1–2 have every score entered. Administration is locked, so '
          'the matrix can’t change until you unlock it.',
      note: 'Then draw round 3 on the Matrix page.',
    );
  });

  test('the lock does not block completing', () {
    final all = stepAt(
      stepFacts(
        state: LifecycleState.running,
        lock: _locked,
        matrix: drawnMatrix(),
        scored: allScored(),
      ),
      minutes: 100,
    );
    expect(all.kind, NextStepKind.completeAllScores);
    final idle = stepAt(
      stepFacts(
        state: LifecycleState.running,
        lock: _locked,
        matrix: drawnMatrix(),
        scored: midRoundTwo(),
      ),
      minutes: 65 + 48 * 60,
    );
    expect(idle.kind, NextStepKind.completeIdle);
  });

  test('the lock does not block publishing or reports', () {
    expect(
      stepAt(
        stepFacts(
          state: LifecycleState.completed,
          lock: _locked,
          publication: PublicationFacts.notPublished,
        ),
      ).kind,
      NextStepKind.publishResults,
    );
    expect(
      stepAt(stepFacts(state: LifecycleState.completed, lock: _locked)).kind,
      NextStepKind.viewReports,
    );
  });

  test('an unlocked contest is never given an unlock step', () {
    for (final state in LifecycleState.values) {
      expect(
        stepAt(
          stepFacts(
            state: state,
            matrix: state == LifecycleState.created ? null : drawnMatrix(),
          ),
        ).kind,
        isNot(NextStepKind.unlock),
        reason: state.name,
      );
    }
  });
}
