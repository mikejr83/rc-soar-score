import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';

/// The running demo contest: 12 pilots, 6 rounds of 3 groups, 4 rounds scored
/// whole and 5 slots of round 5 scored (`demo_contest_plan.dart`).
const _contest = 'Mountain States Team F5J';

Finder _inTile(int ordinal, String text) => find.descendant(
  of: find.byKey(ValueKey('progress-tile-$ordinal')),
  matching: find.text(text),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // One test per file: `launchApp` starts the real app, which holds the demo
  // database and the embedded server's port for the life of the process.
  testWidgets('workspace of a running contest: cards, tiles and links', (
    tester,
  ) async {
    await openMainPage(tester);
    await openContest(tester, _contest);

    // A running contest opens on its workspace.
    await pumpUntilFound(tester, find.byKey(const ValueKey('next-step-card')));

    // Next step: scoring continues at the current round.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('next-step-title')),
        matching: find.textContaining('Continue scoring: round 5'),
      ),
      findsOneWidget,
    );

    // Progress card: headline and one tile for each round.
    await pumpUntilFound(tester, find.byKey(const ValueKey('progress-card')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('progress-where')));
    expect(find.text('Round 5 of 6'), findsOneWidget);
    for (var round = 1; round <= 6; round++) {
      expect(find.byKey(ValueKey('progress-tile-$round')), findsOneWidget);
    }
    expect(_inTile(1, '12/12'), findsOneWidget);
    expect(_inTile(1, 'Scored'), findsOneWidget);
    expect(_inTile(5, 'In progress'), findsOneWidget);
    expect(_inTile(6, 'Not flown'), findsOneWidget);

    // Setup checklist and needs-attention cards are on the page.
    expect(find.byKey(const ValueKey('setup-checklist-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('attention-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('checklist-row-matrix')), findsOneWidget);
    expect(find.byKey(const ValueKey('checklist-row-pilots')), findsOneWidget);

    // The next step's Scoring button says score entry is not built yet.
    await tapVisible(tester, find.byKey(const ValueKey('next-step-primary')));
    await pumpUntilFound(tester, find.text('Scoring is not available yet'));
    await tapVisible(tester, find.text('OK'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Scoring is not available yet'), findsNothing);

    // A progress tile opens Scoring at its round.
    await tapVisible(tester, find.byKey(const ValueKey('progress-tile-5')));
    await pumpUntilFound(tester, find.textContaining('Opened at round 5'));

    // Back on the workspace, the checklist rows open their pages.
    await tapRail(tester, 'Workspace');
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('checklist-row-pilots')),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('checklist-row-pilots')),
    );
    await pumpUntilFound(tester, find.textContaining('Contest ID:'));
    expect(find.byKey(const ValueKey('progress-card')), findsNothing);

    await tapRail(tester, 'Workspace');
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('checklist-row-matrix')),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('checklist-row-matrix')),
    );
    await pumpUntilFound(tester, find.byKey(const ValueKey('fairness-score')));
    expect(find.byKey(const ValueKey('progress-card')), findsNothing);
  });
}
