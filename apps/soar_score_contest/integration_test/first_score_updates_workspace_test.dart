import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';

/// A ready demo contest: 14 pilots and a drawn matrix, nothing scored yet.
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

  testWidgets('the first saved score moves the workspace on (#429)', (
    tester,
  ) async {
    await openMainPage(tester);
    await openContest(tester, _contest);

    // Before any score: the setup checklist shows and the next step is to
    // start scoring.
    await pumpUntilFound(tester, find.byKey(const ValueKey('next-step-card')));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('setup-checklist-card')),
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('next-step-title'))).data,
      isNot(contains('Continue scoring')),
    );

    // Enter scores opens the first group of the first round.
    final secondary = find.byKey(const ValueKey('next-step-secondary'));
    await tapVisible(
      tester,
      secondary.evaluate().isNotEmpty
          ? secondary
          : find.byKey(const ValueKey('next-step-primary')),
    );
    await pumpUntilFound(tester, find.textContaining('Round 1 of'));
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

    // Back on the workspace the contest is running: no checklist, and the
    // next step continues scoring.
    await tapRail(tester, 'Workspace');
    await pumpUntilFound(tester, find.byKey(const ValueKey('next-step-card')));
    await pumpUntilFound(tester, find.textContaining('Continue scoring'));
    expect(find.byKey(const ValueKey('setup-checklist-card')), findsNothing);
    expect(find.text('Running'), findsWidgets);
  });
}
