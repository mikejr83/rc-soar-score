import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:soar_score_contest/services/new_contest/copy_mode.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';
import 'support/wizard_steps.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('copying "Front Range F5J Open" with all pilots keeps classes '
      'and leaves the helpers behind', (tester) async {
    await openMainPage(tester);

    await openContest(tester, 'Front Range F5J Open');
    await openConfiguration(tester);
    final sourcePilots = configurationCount(tester, 'Scoring pilots');

    await tapVisible(tester, find.byKey(const ValueKey('breadcrumb-contests')));
    await openWizard(tester);

    // 1. Copy configuration and all pilots.
    await chooseCopySource(tester, CopyMode.allPilots, 'Front Range F5J Open');
    await enterWizardDetails(tester, 'E2E Copied Classes');
    await wizardPrimary(tester);

    // 2. Discipline.
    await pumpUntilStep(tester, 'Discipline');
    await wizardPrimary(tester);

    // 3. Classes are on, from the source.
    await pumpUntilStep(tester, 'Participant options');
    expect(
      tester.widget<Switch>(find.byKey(const ValueKey('option-classes'))).value,
      isTrue,
    );
    await wizardPrimary(tester);

    // 4. Participants keep their class, so none needs fixing.
    await pumpUntilStep(tester, 'Participants');
    await wizardPrimary(tester);

    // 5. Scoring.
    await pumpUntilStep(tester, 'Scoring & publication');
    await wizardPrimary(tester);

    // 6. Draw options: 3 groups, 8 rounds, like the source.
    await pumpUntilStep(tester, 'Draw options');
    await enterIn(tester, fieldWithKey('groups-per-round'), '3');
    await enterIn(tester, fieldWithKey('preliminary-rounds'), '8');
    await wizardPrimary(tester);

    // 7. Summary and create.
    await pumpUntilFound(tester, find.byKey(const ValueKey('summary-Details')));
    await wizardPrimary(tester);

    await pumpUntilFound(tester, find.text('Scoring pilots'));
    expect(find.text('E2E Copied Classes'), findsWidgets);
    expect(configurationCount(tester, 'Scoring pilots'), sourcePilots);
    // The source's helpers are not copied.
    expect(configurationCount(tester, 'Other participants'), 0);
  });
}
