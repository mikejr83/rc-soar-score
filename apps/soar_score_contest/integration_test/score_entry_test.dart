import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';

/// The running demo contest: round 5 has 5 of its 12 slots scored.
const _contest = 'Mountain States Team F5J';

Finder _timeFields() => find.byWidgetPredicate(
  (w) =>
      w is TextField &&
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith('score-time-'),
  description: 'a time field',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('official score entry: open a group, enter a time, save it', (
    tester,
  ) async {
    await openMainPage(tester);
    await openContest(tester, _contest);
    await pumpUntilFound(tester, find.byKey(const ValueKey('progress-tile-5')));

    // The progress tile opens Scoring at round 5.
    await tapVisible(tester, find.byKey(const ValueKey('progress-tile-5')));
    await pumpUntilFound(tester, find.text('Round 5 of 6'));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('scoring-context-strip')),
    );

    // Navigation: the group picker lists every group of the round.
    await tapVisible(tester, find.byKey(const ValueKey('group-picker')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('picker-item-3')));
    expect(find.text('Group C'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('picker-item-3')));
    await pumpUntilFound(tester, find.textContaining('Group C of 3'));

    // Group C is not scored. Open its first row and enter a flight.
    final time = _timeFields().first;
    await pumpUntilFound(tester, time);
    await tapVisible(tester, time);
    await enterIn(tester, time, '630');
    await pumpUntilFound(tester, find.text('6:30'));
    final height = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('score-height-'),
    );
    await enterIn(tester, height.first, '180');
    await pumpUntilFound(tester, find.text('1 unsaved row'));

    // Saving the row makes it official, and the strip counts it.
    final save = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('score-save-') &&
          !(w.key! as ValueKey<String>).value.startsWith('score-save-all'),
    );
    await tapVisible(tester, save.first);
    // Group C had one score already; the saved row makes two.
    await pumpUntilFound(tester, find.text('2 of 4 entered · 2 official'));
    await pumpUntilFound(tester, find.text('Nothing to save'));
  });
}
