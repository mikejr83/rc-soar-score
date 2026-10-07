import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/new_contest/scoring_settings.dart';
import 'package:soar_score_contest/services/new_contest/wizard_discipline.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/new_contest_test_support.dart';
import '../support/participants_step_support.dart';

Future<void> _segment(WidgetTester tester, String key, String label) async {
  final button = find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.text(label),
  );
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ALES defaults to Time; changing it warns and can be reset', (
    tester,
  ) async {
    final store = await storeAtStep4(
      participants: [row(0), row(1)],
      discipline: WizardDiscipline.ales,
      options: const {},
      visitedThrough: 5,
    );
    await pumpWizard(tester, respond: stepApi, store: store);

    expect(stepTitle(tester), 'Scoring & publication');
    expect(find.text('Created unpublished and private'), findsOneWidget);
    expect(store.draft.scoringSettings.groupScoreMode, GroupScoreMode.time);
    expect(find.text('ALES default'), findsWidgets);

    await _segment(tester, 'group-score', 'Normalized');
    expect(
      store.draft.scoringSettings.groupScoreMode,
      GroupScoreMode.normalized,
    );
    expect(find.text('No longer a traditional ALES contest'), findsOneWidget);
    expect(find.text('Changed from Time'), findsOneWidget);

    await tester.ensureVisible(find.text('Reset to default'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset to default'));
    await tester.pumpAndSettle();
    expect(store.draft.scoringSettings.groupScoreMode, GroupScoreMode.time);
    expect(find.text('No longer a traditional ALES contest'), findsNothing);
  });

  testWidgets('the precision example follows rounding and places', (
    tester,
  ) async {
    final store = await storeAtStep4(
      participants: [row(0), row(1)],
      options: const {},
      visitedThrough: 5,
    );
    await pumpWizard(tester, respond: stepApi, store: store);

    expect(find.text('Example: 987.4567 → 987.5'), findsOneWidget);
    await _segment(tester, 'rounding', 'Truncate');
    expect(find.text('Example: 987.4567 → 987.4'), findsOneWidget);
    await _segment(tester, 'decimal-places', '3');
    expect(find.text('Example: 987.4567 → 987.456'), findsOneWidget);
  });

  testWidgets('two dropped rounds: the second must come after the first', (
    tester,
  ) async {
    final store = await storeAtStep4(
      participants: [row(0), row(1)],
      options: const {},
      visitedThrough: 5,
    );
    await pumpWizard(tester, respond: stepApi, store: store);
    // F5J drops one round after round 6 by default.
    expect(store.draft.scoringSettings.dropPolicy, DropPolicy.one);

    await _segment(tester, 'drop-policy', 'Two dropped');
    final second = find.descendant(
      of: find.byKey(const ValueKey('second-drop')),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(second);
    await tester.enterText(second, '4');
    await tester.pumpAndSettle();
    expect(find.text('Must be after round 6.'), findsWidgets);

    await next(tester);
    expect(stepTitle(tester), 'Scoring & publication');

    await tester.enterText(second, '10');
    await tester.pumpAndSettle();
    expect(store.draft.scoringSettings.dropAfterRounds, [6, 10]);
    await next(tester);
    expect(stepTitle(tester), 'Draw options');
  });

  test('defaults come from the platform and each discipline profile', () {
    final ales = ScoringSettings.defaultsFor(WizardDiscipline.ales);
    expect(ales.groupScoreMode, GroupScoreMode.time);
    expect(ales.dropPolicy, DropPolicy.disabled);

    final f3j = ScoringSettings.defaultsFor(WizardDiscipline.f3j);
    expect(f3j.roundingMode, RoundingMode.truncate);
    expect(f3j.dropAfterRounds, [6]);

    final thermal = ScoringSettings.defaultsFor(
      WizardDiscipline.thermalDuration,
    );
    expect(thermal.groupScoreMode, GroupScoreMode.normalized);
    expect(thermal.decimalPlaces, 1);
    expect(thermal.reviewRequests, isTrue);
    expect(thermal.publicUpdateMode, PublicUpdateMode.roundCompletion);
  });

  test('copied options carry their dropped rounds', () {
    final copied = ScoringSettings.fromOptions(
      CoreOptions(dropAfterRounds: const [4, 8], decimalPlaces: 2),
    );
    expect(copied.dropPolicy, DropPolicy.two);
    expect(copied.dropAfterRounds, [4, 8]);
    expect(copied.decimalPlaces, 2);
  });
}
