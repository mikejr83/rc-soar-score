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

  testWidgets('copying "Mountain States Team F5J" with all pilots brings '
      'its teams option and pilots', (tester) async {
    await openMainPage(tester);

    // The source's numbers, read from its configuration page.
    await openContest(tester, 'Mountain States Team F5J');
    await openConfiguration(tester);
    final sourcePilots = configurationCount(tester, 'Scoring pilots');

    await tapVisible(tester, find.byKey(const ValueKey('breadcrumb-contests')));
    await openWizard(tester);

    // 1. Copy configuration and all pilots; the details are still ours.
    await chooseCopySource(
      tester,
      CopyMode.allPilots,
      'Mountain States Team F5J',
    );
    expect(find.text('All $sourcePilots'), findsWidgets);
    await enterWizardDetails(tester, 'E2E Copied Teams');
    await wizardPrimary(tester);

    // 2. Discipline: copied from the source.
    await pumpUntilStep(tester, 'Discipline');
    await wizardPrimary(tester);

    // 3. Participant options: Teams is on, marked as coming from the source,
    // with the source's count of 3 pilots per team score.
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

    // 4. Participants: the copied pilots (teams are never copied).
    await pumpUntilStep(tester, 'Participants');
    await wizardPrimary(tester);

    // 5. Scoring.
    await pumpUntilStep(tester, 'Scoring & publication');
    await wizardPrimary(tester);

    // 6. Draw options: 3 groups of 4, like the source.
    await pumpUntilStep(tester, 'Draw options');
    await enterIn(tester, fieldWithKey('groups-per-round'), '3');
    await enterIn(tester, fieldWithKey('preliminary-rounds'), '6');
    await wizardPrimary(tester);

    // 7. Summary names the source and the teams option, then create.
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
