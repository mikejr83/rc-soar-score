import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/workspace/next_step/next_step.dart';
import 'package:soar_score_contest/services/workspace/next_step/next_step_action.dart';
import 'package:soar_score_contest/services/workspace/next_step/next_step_target.dart';
import 'package:soar_score_contest/services/workspace/publication_facts.dart';
import 'package:soar_score_contest/widgets/workspace/next_step/next_step_card.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../support/matrix_test_support.dart';
import '../../../support/next_step_support.dart';

Future<void> _pump(
  WidgetTester tester,
  NextStep step, {
  bool busy = false,
  bool unavailable = false,
  List<NextStepAction>? pressed,
  double width = 800,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: NextStepCard(
            step: step,
            busy: busy,
            factsUnavailable: unavailable,
            onRetryFacts: () {},
            onPressed: (action) => pressed?.add(action),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('each step renders its words and buttons', () {
    final steps = <String, NextStep>{
      'finish configuration': stepAt(
        stepFacts(state: LifecycleState.created, withConfiguration: false),
      ),
      'add pilots': stepAt(stepFacts(participations: const [])),
      'draw': stepAt(stepFacts()),
      'start scoring': stepAt(
        stepFacts(matrix: drawnMatrix(), scored: const {}),
      ),
      'continue scoring': stepAt(
        stepFacts(
          state: LifecycleState.running,
          matrix: drawnMatrix(),
          scored: midRoundTwo(),
        ),
        minutes: 90,
      ),
      'complete': stepAt(
        stepFacts(
          state: LifecycleState.running,
          matrix: drawnMatrix(),
          scored: allScored(),
        ),
        minutes: 200,
      ),
      'unlock': stepAt(stepFacts(lock: AdminLock.locked)),
      'reports': stepAt(stepFacts(state: LifecycleState.completed)),
      'publish': stepAt(
        stepFacts(
          state: LifecycleState.completed,
          publication: PublicationFacts.notPublished,
        ),
      ),
    };
    steps.forEach((name, step) {
      testWidgets(name, (tester) async {
        await _pump(tester, step);
        expect(find.text(step.eyebrow), findsOneWidget);
        expect(find.text(step.title), findsOneWidget);
        expect(find.text(step.body), findsOneWidget);
        expect(find.text(step.primary.label), findsOneWidget);
        final reason = step.reason;
        if (reason != null) {
          expect(
            find.textContaining(reason.lead, findRichText: true),
            findsOneWidget,
          );
        }
        final secondary = step.secondary;
        if (secondary != null) {
          expect(find.text(secondary.label), findsOneWidget);
        }
        final note = step.note;
        if (note != null) {
          expect(find.text(note), findsOneWidget);
        }
      });
    });
  });

  testWidgets('a suggestion has its own eyebrow and icon', (tester) async {
    final step = stepAt(
      stepFacts(
        state: LifecycleState.running,
        matrix: drawnMatrix(),
        scored: allScored(),
      ),
      minutes: 200,
    );
    await _pump(tester, step);
    expect(find.text('SUGGESTED NEXT STEP'), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    expect(find.byIcon(Icons.flag_outlined), findsNothing);
  });

  testWidgets('a plain step shows the flag eyebrow', (tester) async {
    await _pump(tester, stepAt(stepFacts()));
    expect(find.text('NEXT STEP'), findsOneWidget);
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
  });

  testWidgets('the primary button carries the icon of its target', (
    tester,
  ) async {
    await _pump(tester, stepAt(stepFacts()));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('next-step-primary')),
        matching: find.byIcon(Icons.grid_view),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a button press reports its action', (tester) async {
    final pressed = <NextStepAction>[];
    final step = stepAt(stepFacts());
    await _pump(tester, step, pressed: pressed);
    await tester.tap(find.byKey(const ValueKey('next-step-primary')));
    expect(pressed, [step.primary]);
  });

  testWidgets('busy shows the busy label and a spinner and ignores taps', (
    tester,
  ) async {
    final pressed = <NextStepAction>[];
    final step = stepAt(stepFacts(lock: AdminLock.locked));
    await _pump(tester, step, busy: true, pressed: pressed);
    expect(find.text('Unlocking…'), findsOneWidget);
    expect(find.text('Unlock administration'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('next-step-primary')),
      warnIfMissed: false,
    );
    expect(pressed, isEmpty);
  });

  testWidgets('a disabled publish button keeps its note visible', (
    tester,
  ) async {
    final pressed = <NextStepAction>[];
    final step = stepAt(
      stepFacts(
        state: LifecycleState.completed,
        publication: PublicationFacts.notPublished,
        offline: true,
      ),
    );
    expect(step.primary.target, NextStepTarget.publish);
    await _pump(tester, step, pressed: pressed);
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('next-step-primary')),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Needs a connection.'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('next-step-primary')),
      warnIfMissed: false,
    );
    expect(pressed, isEmpty);
  });

  testWidgets('unavailable facts add a quiet line with Retry', (tester) async {
    await _pump(tester, stepAt(stepFacts()), unavailable: true);
    expect(find.text(nextStepUnavailableText), findsOneWidget);
    expect(find.byKey(const ValueKey('next-step-retry')), findsOneWidget);
  });

  testWidgets('without unavailable facts there is no Retry', (tester) async {
    await _pump(tester, stepAt(stepFacts()));
    expect(find.text(nextStepUnavailableText), findsNothing);
    expect(find.byKey(const ValueKey('next-step-retry')), findsNothing);
  });

  testWidgets('a narrow window at 200% text scale does not overflow', (
    tester,
  ) async {
    final step = stepAt(stepFacts(lock: AdminLock.locked));
    await _pump(tester, step, width: 320, textScale: 2, unavailable: true);
    expect(tester.takeException(), isNull);
    final buttons = tester.getRect(
      find.byKey(const ValueKey('next-step-primary')),
    );
    expect(buttons.right, lessThanOrEqualTo(320));
  });
}
