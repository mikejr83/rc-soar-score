import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';

/// A ready demo contest: a drawn matrix, nothing scored yet.
const _contest = 'Front Range F5J Open';

Finder _keyed(String prefix) => find.byWidgetPredicate(
  (w) =>
      w is TextField &&
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith(prefix),
  description: 'a $prefix field',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the status panel names the round being scored (#26)', (
    tester,
  ) async {
    await openMainPage(tester);

    // Outside a contest there is no status panel.
    expect(find.byKey(const ValueKey('shell-status-panel')), findsNothing);

    await openContest(tester, _contest);
    final round = find.byKey(const ValueKey('shell-round-status'));
    await pumpUntilFound(tester, round);
    expect(
      find.descendant(of: round, matching: find.text('Not started')),
      findsOneWidget,
    );

    // Choosing it opens the scoring page.
    await tapVisible(tester, round);
    await pumpUntilFound(tester, find.textContaining('Round 1 of'));

    // Save the first score of the first group.
    final time = _keyed('score-time-').first;
    await pumpUntilFound(tester, time);
    await tapVisible(tester, time);
    await enterIn(tester, time, '630');
    await enterIn(tester, _keyed('score-height-').first, '180');
    await pumpUntilFound(tester, find.text('1 unsaved row'));
    final save = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('score-save-') &&
          !(w.key! as ValueKey<String>).value.startsWith('score-save-all'),
    );
    await tapVisible(tester, save.first);
    await pumpUntilFound(tester, find.textContaining('1 official'));

    // Back on the workspace the entry names round 1, group A, and leads back
    // to that group.
    await tapRail(tester, 'Workspace');
    await pumpUntilFound(
      tester,
      find.descendant(of: round, matching: find.textContaining(', group A')),
    );
    expect(
      find.descendant(of: round, matching: find.textContaining('1 of ')),
      findsOneWidget,
    );
    await tapVisible(tester, round);
    await pumpUntilFound(tester, find.textContaining('Round 1 of'));
  });
}
