import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/new_contest/copy_mode.dart';

import '../support/interact.dart';
import '../support/launch_app.dart';
import '../support/open_demo_contest.dart';
import '../support/pump_until_gone.dart';
import '../support/wizard_steps.dart';
import 'journey.dart';

/// Phase 3: the New Contest wizard. The first run makes the contest the later
/// phases use (new, existing and wizard-created pilots; Create blocked until
/// the draft is valid); two more runs copy the demo contests that have
/// classes and teams.
///
/// The steps of the first run are one flow: each continues on the wizard step
/// the previous one left.
Future<void> runWizardPhase(Journey journey, JourneyContext data) async {
  final tester = journey.tester;

  await journey.step('Wizard: details and discipline', () async {
    await goToMainPage(tester);
    await openWizard(tester);
    await enterWizardDetails(tester, data.contestName);
    await enterIn(tester, find.byKey(const ValueKey('contest-city')), 'Golden');
    await enterIn(tester, find.byKey(const ValueKey('contest-region')), 'CO');
    await wizardPrimary(tester);

    await pumpUntilStep(tester, 'Discipline');
    await tapVisible(tester, find.byKey(const ValueKey('discipline-F5J')));
    await wizardPrimary(tester);

    // Participant options: none (no teams, classes or roles).
    await pumpUntilStep(tester, 'Participant options');
    await wizardPrimary(tester);
  });

  await journey.step('Wizard: new and existing participants', () async {
    await pumpUntilStep(tester, 'Participants');
    // People created in the participants manager (phase 2) and demo people.
    for (final name in [
      ...data.pilotNames.take(data.rosterPilots),
      ...data.demoPilots,
    ]) {
      await addWizardPilot(tester, name);
    }
    // A person created inside the wizard.
    final person = data.wizardPerson;
    await tapVisible(tester, find.byKey(const ValueKey('add-participant-new')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('first-name')));
    await enterIn(
      tester,
      find.byKey(const ValueKey('first-name')),
      person.first,
    );
    await enterIn(tester, find.byKey(const ValueKey('last-name')), person.last);
    await enterIn(tester, find.byKey(const ValueKey('email')), person.email);
    // The first tap can only move focus off the email field, which starts
    // its check and shifts the layout; tap again if the editor is still open
    // a few seconds later (a closing editor stays on screen for a moment).
    final save = find.byKey(const ValueKey('save-participant'));
    for (var attempt = 0; attempt < 3; attempt++) {
      await tapVisible(tester, save);
      for (var i = 0; i < 15 && save.evaluate().isNotEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      if (save.evaluate().isEmpty) {
        break;
      }
    }
    await pumpUntilGone(tester, save);
    await pumpUntilFound(
      tester,
      find.text('${person.first} ${person.last} is added as Pilot.'),
    );
    await wizardPrimary(tester);
  });

  await journey.step('Wizard: scoring defaults and draw options', () async {
    await pumpUntilStep(tester, 'Scoring & publication');
    await wizardPrimary(tester);

    await pumpUntilStep(tester, 'Draw options');
    await enterIn(
      tester,
      fieldWithKey('groups-per-round'),
      '${data.groupsPerRound}',
    );
    await enterIn(tester, fieldWithKey('preliminary-rounds'), '${data.rounds}');
    await wizardPrimary(tester);
    await pumpUntilStep(tester, 'Summary & create');
    expect(find.byKey(const ValueKey('wizard-blocked-reason')), findsNothing);
  });

  await journey.step(
    'Wizard: Create is blocked while a step is invalid',
    () async {
      // Edit Details from the summary and empty the name.
      await tapVisible(tester, find.byKey(const ValueKey('edit-Details')));
      await pumpUntilStep(tester, 'Details & copy source');
      await enterIn(tester, find.byKey(const ValueKey('contest-name')), '');

      // Back on the summary, Create gives a reason and does nothing.
      await goToWizardStep(tester, 7);
      await pumpUntilStep(tester, 'Summary & create');
      final reason = find.byKey(const ValueKey('wizard-blocked-reason'));
      await pumpUntilFound(tester, reason);
      expect(tester.widget<Text>(reason).data, contains('Can’t create yet'));
      await wizardPrimary(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(wizardStepTitle(tester), 'Summary & create');

      // The reason's fix link goes to the step that needs attention.
      await tapVisible(
        tester,
        find.widgetWithText(TextButton, 'Go to Details & copy source'),
      );
      await pumpUntilStep(tester, 'Details & copy source');
      await enterIn(
        tester,
        find.byKey(const ValueKey('contest-name')),
        data.contestName,
      );
      await nextUntilSummary(tester);
      expect(find.byKey(const ValueKey('wizard-blocked-reason')), findsNothing);
    },
  );

  await journey.step('Wizard: create the contest', () async {
    await wizardPrimary(tester);
    await pumpUntilFound(tester, find.text('Scoring pilots'));
    expect(find.text(data.contestName), findsWidgets);
    expect(
      configurationCount(tester, 'Scoring pilots'),
      data.pilotNames.length,
    );
    expect(configurationCount(tester, 'Other participants'), 0);
  });

  await journey.step('Models: entered in the wizard, edited on the '
      'Participants page', () async {
    final first = data.demoPilots.first;
    final second = data.demoPilots.last;
    await goToMainPage(tester);
    await openWizard(tester);
    await enterWizardDetails(tester, 'E2E Models');
    await wizardPrimary(tester);
    await pumpUntilStep(tester, 'Discipline');
    await tapVisible(tester, find.byKey(const ValueKey('discipline-F5J')));
    await wizardPrimary(tester);

    // Models is the only option on.
    await pumpUntilStep(tester, 'Participant options');
    await tapVisible(tester, find.byKey(const ValueKey('option-models')));
    await wizardPrimary(tester);

    await pumpUntilStep(tester, 'Participants');
    await addWizardPilot(tester, first);
    await addWizardPilot(tester, second);
    // Both pilots start with the notice, which does not block continuing.
    expect(find.text('No models entered'), findsNWidgets(2));
    expect(find.textContaining('fixing before you continue'), findsNothing);

    // The first pilot gets a typed model.
    await tapVisible(tester, _modelsButton.first);
    await pumpUntilFound(tester, find.byKey(const ValueKey('models-done')));
    await tapVisible(tester, find.byKey(const ValueKey('model-add')));
    await enterIn(
      tester,
      find.byKey(const ValueKey('model-name')),
      'E2E Supra',
    );
    await enterIn(
      tester,
      find.byKey(const ValueKey('model-manufacturer')),
      'E2E Models Co',
    );
    await tapVisible(tester, find.byKey(const ValueKey('model-save')));
    await pumpUntilFound(tester, find.text('E2E Supra · E2E Models Co'));
    await tapVisible(tester, find.byKey(const ValueKey('models-done')));
    await pumpUntilGone(tester, find.byKey(const ValueKey('models-done')));
    expect(find.text('E2E Supra · E2E Models Co'), findsOneWidget);
    expect(find.text('No models entered'), findsOneWidget);
    await wizardPrimary(tester);

    await pumpUntilStep(tester, 'Scoring & publication');
    await wizardPrimary(tester);
    await pumpUntilStep(tester, 'Draw options');
    await enterIn(tester, fieldWithKey('groups-per-round'), '1');
    await enterIn(tester, fieldWithKey('preliminary-rounds'), '2');
    await wizardPrimary(tester);
    await pumpUntilFound(tester, find.byKey(const ValueKey('summary-Details')));
    expect(find.textContaining('1 entered'), findsOneWidget);
    await wizardPrimary(tester);
    await pumpUntilFound(tester, find.text('Scoring pilots'));

    // The Participants page shows what was saved, and the pilot without a
    // model still shows only the notice.
    await tapRail(tester, 'Participants');
    await pumpUntilFound(tester, find.text('E2E Supra · E2E Models Co'));
    expect(find.text('No models entered'), findsOneWidget);

    // A model is added to the second pilot, edited, then removed.
    await tapVisible(tester, _modelsButton.last);
    await pumpUntilFound(tester, find.byKey(const ValueKey('model-add')));
    await tapVisible(tester, find.byKey(const ValueKey('model-add')));
    // Blake's demo profile has a model to pick.
    await tapVisible(tester, find.byKey(const ValueKey('model-pick')));
    await tapVisible(tester, find.text('Demo Mini · Demo Models').last);
    await enterIn(
      tester,
      find.byKey(const ValueKey('model-contest-id')),
      'E2E-7',
    );
    await tapVisible(tester, find.byKey(const ValueKey('model-save')));
    await pumpUntilFound(tester, find.textContaining('Contest E2E-7'));
    await tapVisible(
      tester,
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('edit-model-'),
        description: 'the edit model button',
      ),
    );
    await enterIn(
      tester,
      find.byKey(const ValueKey('model-name')),
      'E2E Spare Two',
    );
    await tapVisible(tester, find.byKey(const ValueKey('model-save')));
    await pumpUntilFound(tester, find.textContaining('E2E Spare Two'));
    await tapVisible(tester, find.byKey(const ValueKey('models-done')));
    await pumpUntilFound(tester, find.textContaining('E2E Spare Two'));
    expect(find.text('No models entered'), findsNothing);

    await tapVisible(tester, _modelsButton.last);
    await pumpUntilFound(tester, find.byKey(const ValueKey('model-add')));
    await tapVisible(
      tester,
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('remove-model-'),
        description: 'the remove model button',
      ),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('models-dialog-empty')),
    );
    await tapVisible(tester, find.byKey(const ValueKey('models-done')));
    await pumpUntilFound(tester, find.text('No models entered'));
    expect(find.textContaining('E2E Spare Two'), findsNothing);
  });

  await journey.step('Copying a contest with classes', () async {
    await goToMainPage(tester);
    await openContest(tester, 'Front Range F5J Open');
    await openConfiguration(tester);
    final sourcePilots = configurationCount(tester, 'Scoring pilots');

    await goToMainPage(tester);
    await openWizard(tester);

    // 1. Copy configuration and all pilots.
    await chooseCopySource(tester, CopyMode.allPilots, 'Front Range F5J Open');
    await enterWizardDetails(tester, 'E2E Copied Classes');
    await wizardPrimary(tester);

    await pumpUntilStep(tester, 'Discipline');
    await wizardPrimary(tester);

    // Classes are on, from the source.
    await pumpUntilStep(tester, 'Participant options');
    expect(
      tester.widget<Switch>(find.byKey(const ValueKey('option-classes'))).value,
      isTrue,
    );
    await wizardPrimary(tester);

    // Participants keep their class, so none needs fixing.
    await pumpUntilStep(tester, 'Participants');
    await wizardPrimary(tester);

    await pumpUntilStep(tester, 'Scoring & publication');
    await wizardPrimary(tester);

    await pumpUntilStep(tester, 'Draw options');
    await enterIn(tester, fieldWithKey('groups-per-round'), '3');
    await enterIn(tester, fieldWithKey('preliminary-rounds'), '8');
    await wizardPrimary(tester);

    await pumpUntilFound(tester, find.byKey(const ValueKey('summary-Details')));
    await wizardPrimary(tester);

    await pumpUntilFound(tester, find.text('Scoring pilots'));
    expect(find.text('E2E Copied Classes'), findsWidgets);
    expect(configurationCount(tester, 'Scoring pilots'), sourcePilots);
    // The source's helpers are not copied.
    expect(configurationCount(tester, 'Other participants'), 0);
  });

  await journey.step('Copying a contest with teams', () async {
    await goToMainPage(tester);
    await openContest(tester, 'Mountain States Team F5J');
    await openConfiguration(tester);
    final sourcePilots = configurationCount(tester, 'Scoring pilots');

    await goToMainPage(tester);
    await openWizard(tester);

    // Copy configuration and all pilots; the details are still ours.
    await chooseCopySource(
      tester,
      CopyMode.allPilots,
      'Mountain States Team F5J',
    );
    expect(find.text('All $sourcePilots'), findsWidgets);
    await enterWizardDetails(tester, 'E2E Copied Teams');
    await wizardPrimary(tester);

    await pumpUntilStep(tester, 'Discipline');
    await wizardPrimary(tester);

    // Teams is on, marked as coming from the source, with its count of 3
    // pilots per team score.
    await pumpUntilStep(tester, 'Participant options');
    expect(
      tester.widget<Switch>(find.byKey(const ValueKey('option-teams'))).value,
      isTrue,
    );
    expect(find.text('From source'), findsWidgets);
    expect(
      tester
          .widget<TextField>(fieldWithKey('team-pilot-count'))
          .controller!
          .text,
      '3',
    );
    await wizardPrimary(tester);

    // The copied pilots (teams are never copied).
    await pumpUntilStep(tester, 'Participants');
    await wizardPrimary(tester);

    await pumpUntilStep(tester, 'Scoring & publication');
    await wizardPrimary(tester);

    await pumpUntilStep(tester, 'Draw options');
    await enterIn(tester, fieldWithKey('groups-per-round'), '3');
    await enterIn(tester, fieldWithKey('preliminary-rounds'), '6');
    await wizardPrimary(tester);

    // The summary names the source and the teams option, then create.
    await pumpUntilFound(tester, find.byKey(const ValueKey('summary-Details')));
    expect(find.text('Mountain States Team F5J'), findsWidgets);
    expect(
      find.textContaining('Teams (3 count for team score)'),
      findsOneWidget,
    );
    await wizardPrimary(tester);

    await pumpUntilFound(tester, find.text('Scoring pilots'));
    expect(find.text('E2E Copied Teams'), findsWidgets);
    expect(configurationCount(tester, 'Scoring pilots'), sourcePilots);
  });
}

/// The buttons that edit a pilot's models, in row order.
final Finder _modelsButton = find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith('edit-models-'),
  description: 'a pilot models button',
);
