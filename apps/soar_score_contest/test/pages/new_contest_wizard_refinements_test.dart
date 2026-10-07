import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/new_contest/scoring_settings.dart';
import 'package:soar_score_contest/services/new_contest/draw_settings.dart';
import 'package:soar_score_contest/services/new_contest/wizard_discipline.dart';

import '../support/new_contest_test_support.dart';
import '../support/participants_step_support.dart';

void main() {
  testWidgets('Two dropped on F5J marks the second drop as changed, and '
      'review and publication settings show no discipline default', (
    tester,
  ) async {
    final store = await storeAtStep4(
      participants: [row(0), row(1)],
      discipline: WizardDiscipline.f5j,
      options: const {},
      visitedThrough: 5,
    );
    await pumpWizard(tester, respond: stepApi, store: store);

    expect(stepTitle(tester), 'Scoring & publication');
    expect(find.text('Total score decimal precision'), findsOneWidget);
    // Group score, rounding, precision, drop policy and the first drop.
    expect(find.text('F5J default'), findsNWidgets(5));

    final two = find.descendant(
      of: find.byKey(const ValueKey('drop-policy')),
      matching: find.text('Two dropped'),
    );
    await tester.ensureVisible(two);
    await tester.tap(two);
    await tester.pumpAndSettle();

    expect(find.text('Changed from F5J standard (one dropped)'), findsOne);
    expect(find.text('F5J default'), findsNWidgets(4));
  });

  testWidgets('preliminary rounds follow the dropped rounds', (tester) async {
    final store = await storeAtStep4(
      participants: [row(0), row(1)],
      discipline: WizardDiscipline.f5j,
      options: const {},
      visitedThrough: 6,
    );
    await pumpWizard(tester, respond: stepApi, store: store);

    String rounds() => tester
        .widget<TextField>(
          find.descendant(
            of: find.byKey(const ValueKey('preliminary-rounds')),
            matching: find.byType(TextField),
          ),
        )
        .controller!
        .text;

    expect(stepTitle(tester), 'Draw options');
    expect(rounds(), '6');
    expect(
      find.text('Rounds can be appended after the contest starts.'),
      findsOneWidget,
    );
    expect(store.draft.roundsText, '6');

    await store.update(
      store.draft.copyWith(
        scoring: store.draft.scoringSettings.copyWith(
          dropPolicy: DropPolicy.two,
        ),
      ),
    );
    expect(store.draft.roundsText, '12');

    await store.update(
      store.draft.copyWith(
        scoring: store.draft.scoringSettings.copyWith(
          dropPolicy: DropPolicy.disabled,
        ),
      ),
    );
    expect(store.draft.roundsText, DrawSettings.defaultRounds);
  });

  test('creation ids are kept for a retry and replaced once the draft '
      'changes', () async {
    final store = await storeAtStep4(
      participants: [row(0), row(1)],
      options: const {},
      visitedThrough: 7,
    );
    final first = store.creationIdsFor(store.draft);
    expect(store.creationIdsFor(store.draft), same(first));

    final renamed = store.draft.copyWith(name: 'Renamed Cup');
    final second = store.creationIdsFor(renamed);
    expect(second, isNot(same(first)));
    expect(second.contest, isNot(first.contest));
    expect(store.creationIdsFor(renamed), same(second));
  });
}
