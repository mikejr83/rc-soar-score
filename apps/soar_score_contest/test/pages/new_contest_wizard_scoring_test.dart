import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
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
    final l10n = AppLocalizationsEn();
    final store = await storeAtStep4(
      participants: [row(0), row(1)],
      discipline: WizardDiscipline.ales,
      options: const {},
      visitedThrough: 5,
    );
    await pumpWizard(tester, respond: stepApi, store: store);

    expect(stepTitle(tester), l10n.wizardStepScoringPublication);
    expect(find.text(l10n.wizardCreatedUnpublished), findsOneWidget);
    expect(store.draft.scoringSettings.groupScoreMode, GroupScoreMode.time);
    expect(find.text('ALES default'), findsWidgets);

    await _segment(tester, 'group-score', l10n.wizardGroupScoreNormalized);
    expect(
      store.draft.scoringSettings.groupScoreMode,
      GroupScoreMode.normalized,
    );
    expect(find.text(l10n.wizardGroupScoreTraditional('ALES')), findsOneWidget);
    expect(find.text(l10n.wizardChangedFrom('Time')), findsOneWidget);

    await tester.ensureVisible(find.text(l10n.wizardResetToDefault));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.wizardResetToDefault));
    await tester.pumpAndSettle();
    expect(store.draft.scoringSettings.groupScoreMode, GroupScoreMode.time);
    expect(find.text(l10n.wizardGroupScoreTraditional('ALES')), findsNothing);
  });

  testWidgets('scores become official: a new contest starts at end of round', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();
    final store = await storeAtStep4(
      participants: [row(0), row(1)],
      options: const {},
      visitedThrough: 5,
    );
    await pumpWizard(tester, respond: stepApi, store: store);

    expect(find.text(l10n.scoresBecomeOfficialLabel), findsOneWidget);
    expect(
      store.draft.scoringSettings.scoresBecomeOfficial,
      OfficializationMode.endOfRound,
    );

    final choice = find.byKey(
      const ValueKey('scores-become-official-endOfGroup'),
    );
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pumpAndSettle();
    expect(
      store.draft.scoringSettings.scoresBecomeOfficial,
      OfficializationMode.endOfGroup,
    );

    final manual = find.byKey(const ValueKey('scores-become-official-manual'));
    await tester.ensureVisible(manual);
    await tester.tap(manual);
    await tester.pumpAndSettle();
    expect(
      store.draft.scoringSettings.scoresBecomeOfficial,
      OfficializationMode.manual,
    );
    // It does not touch the public update policy.
    expect(
      store.draft.scoringSettings.publicUpdateMode,
      PublicUpdateMode.roundCompletion,
    );
  });

  testWidgets('the precision example follows rounding and places', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();
    final store = await storeAtStep4(
      participants: [row(0), row(1)],
      options: const {},
      visitedThrough: 5,
    );
    await pumpWizard(tester, respond: stepApi, store: store);

    expect(find.text(l10n.wizardPrecisionExample('987.5')), findsOneWidget);
    await _segment(tester, 'rounding', l10n.wizardRoundingTruncate);
    expect(find.text(l10n.wizardPrecisionExample('987.4')), findsOneWidget);
    await _segment(tester, 'decimal-places', '3');
    expect(find.text(l10n.wizardPrecisionExample('987.456')), findsOneWidget);
  });

  testWidgets('two dropped rounds: the second must come after the first', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();
    final store = await storeAtStep4(
      participants: [row(0), row(1)],
      options: const {},
      visitedThrough: 5,
    );
    await pumpWizard(tester, respond: stepApi, store: store);
    // F5J drops one round after round 6 by default.
    expect(store.draft.scoringSettings.dropPolicy, DropPolicy.one);

    await _segment(tester, 'drop-policy', l10n.wizardDropTwo);
    final second = find.descendant(
      of: find.byKey(const ValueKey('second-drop')),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(second);
    await tester.enterText(second, '4');
    await tester.pumpAndSettle();
    expect(find.text(l10n.wizardValidationMustBeAfterRound(6)), findsWidgets);

    await next(tester);
    expect(stepTitle(tester), l10n.wizardStepScoringPublication);

    await tester.enterText(second, '10');
    await tester.pumpAndSettle();
    expect(store.draft.scoringSettings.dropAfterRounds, [6, 10]);
    await next(tester);
    expect(stepTitle(tester), l10n.wizardStepDrawOptions);
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
    expect(thermal.decimalPlaces, 0);
    expect(thermal.reviewRequests, isTrue);
    expect(thermal.publicUpdateMode, PublicUpdateMode.roundCompletion);
    for (final discipline in WizardDiscipline.values) {
      expect(
        ScoringSettings.defaultsFor(discipline).scoresBecomeOfficial,
        OfficializationMode.endOfRound,
      );
    }
  });

  test('a copied contest keeps its mode, and none stored reads Manually', () {
    final stored = ScoringSettings.fromOptions(
      CoreOptions(scoresBecomeOfficial: OfficializationMode.endOfGroup),
    );
    expect(stored.scoresBecomeOfficial, OfficializationMode.endOfGroup);
    final none = ScoringSettings.fromOptions(CoreOptions.fromMap(const {}));
    expect(none.scoresBecomeOfficial, OfficializationMode.manual);
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
