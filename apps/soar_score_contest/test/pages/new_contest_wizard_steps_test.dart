import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';
import 'package:soar_score_contest/services/new_contest/scoring_settings.dart';
import 'package:soar_score_contest/services/participants/participant_option.dart';
import 'package:soar_score_contest/services/new_contest/wizard_discipline.dart';
import 'package:soar_score_contest/widgets/new_contest/wizard_dot_stepper.dart';
import 'package:soar_score_contest/widgets/new_contest/wizard_step_list.dart';

import 'package:soar_score_core/soar_score_core.dart';

import '../support/new_contest_test_support.dart';

Future<void> _pick(WidgetTester tester, String name) async {
  final card = find.byKey(ValueKey('discipline-$name'));
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('step 1 blocks Next with a summary and inline errors, and the '
      'summary links focus the field', (tester) async {
    final l10n = AppLocalizationsEn();
    await pumpWizard(tester, respond: emptyApi);

    expect(find.byType(WizardStepList), findsOneWidget);
    expect(stepTitle(tester), l10n.wizardStepDetailsCopySource);
    expect(find.text(l10n.wizardNext(l10n.wizardStepDiscipline)), findsOneWidget);
    // No errors before trying to continue.
    expect(find.byKey(const ValueKey('banner-validation')), findsNothing);

    await next(tester);
    expect(stepTitle(tester), l10n.wizardStepDetailsCopySource);
    expect(
      find.text(l10n.wizardFieldsNeedAttention(4)),
      findsOneWidget,
    );
    expect(find.text('${l10n.wizardDetailsFieldContestName}: ${l10n.wizardValidationEnterName}'), findsOneWidget);
    // Inline, next to the field.
    expect(find.text(l10n.wizardValidationEnterName), findsOneWidget);
    expect(find.text('Current · needs attention'), findsOneWidget);

    await tester.tap(find.text('${l10n.wizardDetailsFieldContestName}: ${l10n.wizardValidationEnterName}'));
    await tester.pump();
    final name = tester.widget<TextField>(
      find.byKey(const ValueKey('contest-name')),
    );
    expect(name.focusNode!.hasFocus, isTrue);
  });

  testWidgets('the end date follows the start date unless a later one is '
      'chosen', (tester) async {
    await pumpWizard(tester, respond: emptyApi);
    String endText() => tester
        .widget<TextField>(find.byKey(const ValueKey('contest-end')))
        .controller!
        .text;

    await tester.enterText(
      find.byKey(const ValueKey('contest-start')),
      'Nov 14, 2026',
    );
    await tester.pump();
    expect(endText(), 'Nov 14, 2026');

    await tester.enterText(
      find.byKey(const ValueKey('contest-end')),
      'Nov 16, 2026',
    );
    await tester.enterText(
      find.byKey(const ValueKey('contest-start')),
      'Nov 15, 2026',
    );
    await tester.pump();
    expect(endText(), 'Nov 16, 2026');
  });

  testWidgets('every discipline card is as tall as the tallest', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();
    await pumpWizard(tester, respond: emptyApi);
    await fillDetails(tester);
    await next(tester);
    expect(stepTitle(tester), l10n.wizardStepDiscipline);

    final heights = {
      for (final discipline in WizardDiscipline.values)
        discipline.name: tester
            .getSize(find.byKey(ValueKey('discipline-${discipline.name}')))
            .height,
    };
    expect(heights.values.toSet(), hasLength(1), reason: '$heights');
  });

  testWidgets('an end date before the start date is an error', (tester) async {
    final l10n = AppLocalizationsEn();
    await pumpWizard(tester, respond: emptyApi);
    await fillDetails(tester);
    await tester.enterText(
      find.byKey(const ValueKey('contest-end')),
      'Nov 13, 2026',
    );
    await next(tester);

    expect(
      find.text(l10n.wizardValidationEndDateBeforeStart('Nov 14, 2026')),
      findsOneWidget,
    );
    expect(find.text(l10n.wizardFieldsNeedAttention(1)), findsOne);
  });

  testWidgets('steps 1 to 3 advance when valid; visited steps can be jumped '
      'to without losing values', (tester) async {
    final l10n = AppLocalizationsEn();
    final wizard = await pumpWizard(tester, respond: emptyApi);
    await fillDetails(tester);
    await next(tester);

    expect(stepTitle(tester), l10n.wizardStepDiscipline);
    expect(find.text(l10n.wizardStepComplete), findsOneWidget);

    // A discipline is required.
    await next(tester);
    expect(find.text(l10n.wizardValidationChooseDiscipline), findsOneWidget);

    // The first pick needs no confirmation; unsupported ones can't be picked.
    await _pick(tester, 'F3K');
    expect(wizard.store.draft.discipline, isNull);
    await _pick(tester, 'F5J');
    expect(find.byType(AlertDialog), findsNothing);
    expect(wizard.store.draft.discipline, WizardDiscipline.f5j);

    await next(tester);
    expect(stepTitle(tester), l10n.wizardStepParticipantOptions);

    // Jump back to step 1: the values are still there.
    await tester.tap(find.byKey(const ValueKey('wizard-step-1')));
    await tester.pumpAndSettle();
    expect(stepTitle(tester), l10n.wizardStepDetailsCopySource);
    expect(find.text('Gator Cup F5J'), findsOneWidget);
    expect(wizard.store.draft.visitedThrough, 3);
  });

  testWidgets('changing the discipline asks first and can be kept', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();
    final wizard = await pumpWizard(tester, respond: emptyApi);
    await fillDetails(tester);
    await next(tester);
    await _pick(tester, 'F5J');

    await _pick(tester, 'F3J');
    expect(find.text(l10n.wizardChangeDisciplineTitle('F3J')), findsOneWidget);
    await tester.tap(find.text(l10n.wizardChangeDisciplineCancel('F5J')));
    await tester.pumpAndSettle();
    expect(wizard.store.draft.discipline, WizardDiscipline.f5j);

    await _pick(tester, 'F3J');
    await tester.tap(find.text(l10n.wizardChangeDisciplineConfirm));
    await tester.pumpAndSettle();
    expect(wizard.store.draft.discipline, WizardDiscipline.f3j);
    expect(
      find.text(l10n.wizardDisciplineChanged('F3J')),
      findsOneWidget,
    );
  });

  testWidgets('changing the discipline keeps the choices it does not own', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();
    final wizard = await pumpWizard(tester, respond: emptyApi);
    await fillDetails(tester);
    await next(tester);
    await _pick(tester, 'F5J');
    await wizard.store.update(
      wizard.store.draft.copyWith(
        scoring: ScoringSettings.defaultsFor(WizardDiscipline.f5j).copyWith(
          groupScoreMode: GroupScoreMode.time,
          reviewRequests: false,
          publicUpdateMode: PublicUpdateMode.manual,
          scoresBecomeOfficial: OfficializationMode.manual,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _pick(tester, 'F3J');
    await tester.tap(find.text(l10n.wizardChangeDisciplineConfirm));
    await tester.pumpAndSettle();

    final scoring = wizard.store.draft.scoringSettings;
    // The discipline's own values are back to the new defaults.
    expect(
      scoring.groupScoreMode,
      ScoringSettings.defaultsFor(WizardDiscipline.f3j).groupScoreMode,
    );
    // The director's other choices are kept, so a contest set to accept
    // scores manually stays that way.
    expect(scoring.scoresBecomeOfficial, OfficializationMode.manual);
    expect(scoring.publicUpdateMode, PublicUpdateMode.manual);
    expect(scoring.reviewRequests, isFalse);
  });

  testWidgets('changing the discipline with untouched scoring uses defaults', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();
    final wizard = await pumpWizard(tester, respond: emptyApi);
    await fillDetails(tester);
    await next(tester);
    await _pick(tester, 'F5J');
    await _pick(tester, 'F3J');
    await tester.tap(find.text(l10n.wizardChangeDisciplineConfirm));
    await tester.pumpAndSettle();

    expect(
      wizard.store.draft.scoringSettings.scoresBecomeOfficial,
      OfficializationMode.endOfRound,
    );
  });

  testWidgets('step 3: Teams needs a positive team count and adds columns', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();
    final wizard = await pumpWizard(tester, respond: emptyApi);
    await fillDetails(tester);
    await next(tester);
    await _pick(tester, 'ALES');
    await next(tester);

    expect(find.byKey(const ValueKey('team-pilot-count')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('option-teams')));
    await tester.pumpAndSettle();
    expect(wizard.store.draft.options, {ParticipantOption.teams});
    expect(find.byKey(const ValueKey('team-pilot-count')), findsOneWidget);
    expect(find.text('${l10n.wizardColumnTeam} ${l10n.wizardColumnOptional}', findRichText: true), findsOneWidget);

    await next(tester);
    expect(stepTitle(tester), l10n.wizardStepParticipantOptions);
    expect(
      find.text('${l10n.wizardTeamPilotCountLabel}: ${l10n.wizardValidationWholeNumber}'),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const ValueKey('team-pilot-count')), '0');
    await tester.pump();
    expect(find.text(l10n.wizardValidationWholeNumber), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('team-pilot-count')), '3');
    await tester.pump();
    await next(tester);

    // Step 4 needs at least 2 scoring pilots.
    expect(stepTitle(tester), l10n.wizardStepParticipants);
    await next(tester);
    expect(stepTitle(tester), l10n.wizardStepParticipants);
    expect(find.text(l10n.wizardMinPilotsBanner), findsOneWidget);
  });

  testWidgets('narrow windows show the dot stepper and reflow the fields', (
    tester,
  ) async {
    final l10n = AppLocalizationsEn();
    await pumpWizard(tester, respond: emptyApi, size: const Size(800, 1180));

    expect(find.byType(WizardStepList), findsNothing);
    expect(find.byType(WizardDotStepper), findsOneWidget);
    expect(
      find.byTooltip(l10n.wizardStepOf(1, 7, l10n.wizardStepDetailsCopySource)),
      findsOne,
    );
    final error = tester.takeException();
    if (error != null) {
      debugPrint((error as FlutterError).toStringDeep());
    }
    expect(error, isNull);
  });
}
