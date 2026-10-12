import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/semantics.dart';
import 'package:soar_score_contest/services/workspace/next_step/next_step_action.dart';
import 'package:soar_score_contest/services/workspace/next_step/next_step_target.dart';
import 'package:soar_score_contest/services/workspace/publication_facts.dart';
import 'package:soar_score_contest/widgets/workspace/next_step/next_step_buttons.dart';
import 'package:soar_score_contest/widgets/workspace/next_step/next_step_card.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/next_step_support.dart';
import '../../../support/next_step_widget_support.dart';

Widget _card(dynamic step) => MaterialApp(
  home: Scaffold(
    body: NextStepCard(step: step, busy: false, onPressed: (_) {}),
  ),
);

void main() {
  test('a scoring button names its round and group', () {
    expect(
      nextStepActionLabel(
        const NextStepAction(
          label: 'Open Scoring',
          target: NextStepTarget.scoring,
          round: 3,
          group: 2,
        ),
      ),
      'Open Scoring at round 3, group B',
    );
  });

  test('a label that already names the round is kept', () {
    expect(
      nextStepActionLabel(
        const NextStepAction(
          label: 'Open Scoring at round 1, group A',
          target: NextStepTarget.scoring,
          round: 1,
          group: 1,
        ),
      ),
      'Open Scoring at round 1, group A',
    );
  });

  test('other buttons keep their label', () {
    expect(
      nextStepActionLabel(
        const NextStepAction(
          label: 'Go to Matrix',
          target: NextStepTarget.matrix,
          round: 2,
        ),
      ),
      'Go to Matrix',
    );
  });

  testWidgets('the primary button is a labelled, focusable button', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_card(stepAt(stepFacts())));
    final node = tester.getSemantics(
      find.byKey(const ValueKey('next-step-primary')),
    );
    expect(node.label, 'Go to Matrix');
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    handle.dispose();
  });

  testWidgets('a disabled button says why in its hint and cannot be tapped', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _card(
        stepAt(
          stepFacts(
            state: LifecycleState.completed,
            publication: PublicationFacts.notPublished,
            offline: true,
          ),
        ),
      ),
    );
    final node = tester.getSemantics(
      find.byKey(const ValueKey('next-step-primary')),
    );
    expect(node.hint, contains('Needs a connection.'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    handle.dispose();
  });

  testWidgets('every reason has an icon and text, not colour alone', (
    tester,
  ) async {
    await tester.pumpWidget(_card(stepAt(stepFacts(lock: AdminLock.locked))));
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.textContaining('Blocked:', findRichText: true), findsOneWidget);
  });

  testWidgets('the section is a labelled region on the page', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpWorkspace(tester, WorkspaceServer(state: LifecycleState.created));
    expect(find.bySemanticsLabel('Next step'), findsWidgets);
    handle.dispose();
  });
}
