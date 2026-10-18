import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';
import 'support/pump_until_gone.dart';

/// A ready demo contest: a drawn matrix, nothing scored yet.
const _contest = 'Front Range F5J Open';

Finder _keyed(String prefix) => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith(prefix) &&
      w is! Text,
  description: 'a $prefix widget',
);

Finder _field(String prefix) => find.byWidgetPredicate(
  (w) =>
      w is TextField &&
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith(prefix),
  description: 'a $prefix field',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('score history shows a correction and a pilot can retire', (
    tester,
  ) async {
    await openMainPage(tester);
    await openContest(tester, _contest);
    await pumpUntilFound(tester, find.byKey(const ValueKey('next-step-card')));

    // Open the first group of the first round.
    final secondary = find.byKey(const ValueKey('next-step-secondary'));
    await tapVisible(
      tester,
      secondary.evaluate().isNotEmpty
          ? secondary
          : find.byKey(const ValueKey('next-step-primary')),
    );
    await pumpUntilFound(tester, find.textContaining('Round 1 of'));
    final time = _field('score-time-').first;
    await pumpUntilFound(tester, time);

    // Enter a flight on the first row and save it.
    await tapVisible(tester, time);
    await enterIn(tester, time, '630');
    await enterIn(tester, _field('score-height-').first, '180');
    await pumpUntilFound(tester, find.text('1 unsaved row'));
    final save = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('score-save-') &&
          !(w.key! as ValueKey<String>).value.startsWith('score-save-all'),
    );
    await tapVisible(tester, save.first);
    await pumpUntilFound(tester, find.textContaining('1 official'));

    // Correct it: the second save is the next revision.
    await tapVisible(tester, _field('score-time-').first);
    await enterIn(tester, _field('score-time-').first, '640');
    await pumpUntilFound(tester, find.text('1 unsaved row'));
    await tapVisible(tester, save.first);
    await pumpUntilGone(tester, find.text('1 unsaved row'));

    // The history lists both revisions and the reason of the correction.
    await tapVisible(tester, _keyed('row-menu-').first);
    await pumpUntilFound(tester, find.byKey(const ValueKey('menu-history')));
    await tapVisible(tester, find.byKey(const ValueKey('menu-history')));
    await pumpUntilFound(tester, find.text('Revision 2'));
    expect(find.text('Revision 1'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
    expect(find.text('Replaced'), findsOneWidget);
    expect(find.text('Reason: Corrected on the scoring page'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('score-history-close')));

    // The group history shows the same pilot.
    await tapVisible(tester, find.byKey(const ValueKey('group-more')));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('menu-group-history')),
    );
    await tapVisible(tester, find.byKey(const ValueKey('menu-group-history')));
    await pumpUntilFound(tester, find.text('Group history'));
    expect(find.text('Revision 2'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('score-history-close')));

    // Retire the pilot of the second row, who has no score.
    await tapVisible(tester, _keyed('row-menu-').at(1));
    await pumpUntilFound(tester, find.byKey(const ValueKey('menu-retire')));
    await tapVisible(tester, find.byKey(const ValueKey('menu-retire')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('retire-dialog')));
    expect(find.textContaining('flights instead of'), findsWidgets);
    await tapVisible(tester, find.byKey(const ValueKey('retire-confirm')));
    await pumpUntilFound(tester, find.text('Retired'));
    expect(find.text('Retired from round 1'), findsOneWidget);
  });
}
