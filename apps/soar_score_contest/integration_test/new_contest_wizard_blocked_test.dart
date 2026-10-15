import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/wizard_steps.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Create is blocked with a reason while a step is invalid, and '
      'the summary leads back to fix it', (tester) async {
    await openMainPage(tester);
    await openWizard(tester);

    // A complete, valid draft up to the summary.
    await enterWizardDetails(tester, 'E2E Blocked Contest');
    await wizardPrimary(tester);
    await tapVisible(tester, find.byKey(const ValueKey('discipline-F5J')));
    await wizardPrimary(tester);
    await wizardPrimary(tester);
    for (final name in demoPilots) {
      await addWizardPilot(tester, name);
    }
    await wizardPrimary(tester);
    await wizardPrimary(tester);
    await enterIn(tester, fieldWithKey('groups-per-round'), '2');
    await enterIn(tester, fieldWithKey('preliminary-rounds'), '3');
    await wizardPrimary(tester);
    await pumpUntilStep(tester, 'Summary & create');
    expect(find.byKey(const ValueKey('wizard-blocked-reason')), findsNothing);

    // Edit Details from the summary and empty the name.
    await tapVisible(tester, find.byKey(const ValueKey('edit-Details')));
    await pumpUntilStep(tester, 'Details & copy source');
    await enterIn(tester, find.byKey(const ValueKey('contest-name')), '');

    // Back on the summary, Create gives a reason and does nothing.
    await goToWizardStep(tester, 7);
    await pumpUntilStep(tester, 'Summary & create');
    final reason = find.byKey(const ValueKey('wizard-blocked-reason'));
    await pumpUntilFound(tester, reason);
    expect(
      find.descendant(
        of: reason,
        matching: find.textContaining('Can’t create'),
      ),
      findsNothing,
    );
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
      'E2E Blocked Fixed',
    );

    // Valid again: the block is gone and Create makes the contest.
    await nextUntilSummary(tester);
    expect(find.byKey(const ValueKey('wizard-blocked-reason')), findsNothing);
    await wizardPrimary(tester);
    await pumpUntilFound(tester, find.text('Scoring pilots'));
    expect(find.text('E2E Blocked Fixed'), findsWidgets);
    expect(configurationCount(tester, 'Scoring pilots'), demoPilots.length);
  });
}
