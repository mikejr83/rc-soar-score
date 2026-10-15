import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/pages/new_contest_wizard_page.dart';
import 'package:soar_score_contest/services/new_contest/copy_mode.dart';
import 'package:soar_score_contest/widgets/new_contest/source_contest_tile.dart';

import 'interact.dart';
import 'launch_app.dart';

/// The first people of the demo roster, in the order the demo contests use
/// them.
const demoPilots = [
  'Avery Brooks',
  'Blake Castillo',
  'Casey Dunn',
  'Devon Ellis',
];

/// From the main page, opens the New Contest wizard through the rail's
/// Create contest (or Continue configuration) button.
Future<void> openWizard(WidgetTester tester) async {
  final entry = find.byKey(const ValueKey('create-contest'));
  await pumpUntilFound(tester, entry);
  await tapVisible(tester, entry);
  await pumpUntilFound(tester, find.byType(NewContestWizardPage));
}

/// Presses the footer's primary action (Next, or Create on the last step).
Future<void> wizardPrimary(WidgetTester tester) =>
    tapVisible(tester, find.byKey(const ValueKey('wizard-primary')));

/// The title of the step on screen.
String wizardStepTitle(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('wizard-step-title'))).data!;

/// The label of the rail's create-contest entry: its tooltip while the rail
/// is collapsed (an icon button), its text once the rail is expanded.
String createContestEntryLabel(WidgetTester tester) {
  final entry = find.byKey(const ValueKey('create-contest'));
  final button = tester.widget<FloatingActionButton>(entry);
  if (button.tooltip != null) {
    return button.tooltip!;
  }
  return tester
      .widget<Text>(find.descendant(of: entry, matching: find.byType(Text)))
      .data!;
}

/// Waits for the step called [title].
Future<void> pumpUntilStep(WidgetTester tester, String title) => pumpUntilFound(
  tester,
  // The key sits on the title's Text itself, so match the Text by its data.
  find.byWidgetPredicate(
    (w) =>
        w is Text &&
        w.key == const ValueKey('wizard-step-title') &&
        w.data == title,
    description: 'wizard step title "$title"',
  ),
);

/// Jumps to step [number] through the step list (wide windows) or the dots
/// (narrow ones).
Future<void> goToWizardStep(WidgetTester tester, int number) async {
  final list = find.byKey(ValueKey('wizard-step-$number'));
  final dot = find.byKey(ValueKey('wizard-dot-$number'));
  await tapVisible(tester, list.evaluate().isNotEmpty ? list : dot);
}

/// Fills the required fields of step 1.
Future<void> enterWizardDetails(WidgetTester tester, String name) async {
  await enterIn(tester, find.byKey(const ValueKey('contest-name')), name);
  await enterIn(
    tester,
    find.byKey(const ValueKey('contest-venue')),
    'E2E Field',
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
}

/// Finds the demo person [name] in step 4's search and adds them.
Future<void> addWizardPilot(WidgetTester tester, String name) async {
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

/// In step 1, chooses what to copy ([mode]) and the source contest called
/// [sourceName], then waits for the copy summary.
Future<void> chooseCopySource(
  WidgetTester tester,
  CopyMode mode,
  String sourceName,
) async {
  await tapVisible(tester, find.byKey(ValueKey('copy-mode-${mode.name}')));
  final tile = find.descendant(
    of: find.byType(SourceContestTile),
    matching: find.text(sourceName),
  );
  await pumpUntilFound(tester, tile.first);
  await tapVisible(tester, tile.first);
  await pumpUntilFound(tester, find.byKey(const ValueKey('copy-summary')));
}

/// Presses Next until the summary step shows.
Future<void> nextUntilSummary(WidgetTester tester) async {
  final summary = find.byKey(const ValueKey('summary-Details'));
  for (var i = 0; i < 7 && summary.evaluate().isEmpty; i++) {
    await wizardPrimary(tester);
  }
  await pumpUntilFound(tester, summary);
}
