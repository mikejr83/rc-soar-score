import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:soar_score_contest/pages/new_contest_wizard_page.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';

/// The first eight people of the demo roster: the pilots of the demo contest
/// "Autumn F5J Classic".
const _pilots = [
  'Avery Brooks',
  'Blake Castillo',
  'Casey Dunn',
  'Devon Ellis',
  'Emery Foster',
  'Finley Garcia',
  'Harper Hughes',
  'Indigo Ito',
];

Future<void> _next(WidgetTester tester) async {
  await tapVisible(tester, find.byKey(const ValueKey('wizard-primary')));
}

Future<void> _addPilot(WidgetTester tester, String name) async {
  final search = find.descendant(
    of: find.byKey(const ValueKey('participant-search')),
    matching: find.byType(TextField),
  );
  await enterIn(tester, search, name);
  final result = find.widgetWithText(ListTile, name);
  await pumpUntilFound(tester, result);
  await tester.tap(result);
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the new contest wizard builds the demo contest "Autumn F5J '
      'Classic"', (tester) async {
    await openMainPage(tester);

    // The demo contest's numbers, read from its configuration page.
    await openContest(tester, 'Autumn F5J Classic');
    await openConfiguration(tester);
    final demoPilots = configurationCount(tester, 'Scoring pilots');
    final demoOthers = configurationCount(tester, 'Other participants');
    expect(demoPilots, _pilots.length);

    // Back to the contest list and the wizard.
    await tapRail(tester, 'Contests');
    await pumpUntilFound(tester, find.byKey(const ValueKey('create-contest')));
    await tapVisible(tester, find.byKey(const ValueKey('create-contest')));
    await pumpUntilFound(tester, find.byType(NewContestWizardPage));

    // 1. Details, like the demo contest (the name differs to tell them apart).
    await enterIn(
      tester,
      find.byKey(const ValueKey('contest-name')),
      'E2E Autumn F5J Classic',
    );
    await enterIn(
      tester,
      find.byKey(const ValueKey('contest-venue')),
      'Golden Field',
    );
    await enterIn(
      tester,
      find.byKey(const ValueKey('contest-start')),
      'Sep 12, 2026',
    );
    await enterIn(
      tester,
      find.byKey(const ValueKey('contest-end')),
      'Sep 13, 2026',
    );
    await enterIn(tester, find.byKey(const ValueKey('contest-city')), 'Golden');
    await enterIn(tester, find.byKey(const ValueKey('contest-region')), 'CO');
    await _next(tester);

    // 2. Discipline.
    await tapVisible(tester, find.byKey(const ValueKey('discipline-F5J')));
    await _next(tester);

    // 3. Participant options: none (no teams, classes or roles).
    await _next(tester);

    // 4. Participants: the demo contest's pilots.
    for (final name in _pilots) {
      await _addPilot(tester, name);
    }
    await _next(tester);

    // 5. Scoring and publication: the defaults.
    await _next(tester);

    // 6. Draw options: 2 groups and 5 preliminary rounds, like the demo.
    await enterIn(tester, fieldWithKey('groups-per-round'), '2');
    await enterIn(tester, fieldWithKey('preliminary-rounds'), '5');
    await _next(tester);

    // 7. Summary and create.
    await pumpUntilFound(tester, find.byKey(const ValueKey('summary-Details')));
    await _next(tester);

    // The new contest's configuration page opens.
    await pumpUntilFound(tester, find.text('Scoring pilots'));
    expect(find.text('E2E Autumn F5J Classic'), findsWidgets);
    expect(configurationCount(tester, 'Scoring pilots'), demoPilots);
    expect(configurationCount(tester, 'Other participants'), demoOthers);
  });
}
