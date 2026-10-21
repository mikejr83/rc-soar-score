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

/// The `score-row-<id>` key of the row that holds [text], for locating a row
/// by a cell such as the `30 total` cumulative penalty.
ValueKey<String> _rowContaining(String text) {
  final key = find
      .ancestor(
        of: find.text(text),
        matching: find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('score-row-'),
        ),
      )
      .evaluate()
      .first
      .widget
      .key! as ValueKey<String>;
  return key;
}

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

    // The count already there depends on the draw, so it is read, not assumed.
    await pumpUntilFound(tester, find.textContaining(' of 4 entered · '));
    final counts = RegExp(r'^(\d+) of 4 entered · (\d+) official$');
    final before = find
        .byType(Text)
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .map((t) => t == null ? null : counts.firstMatch(t))
        .whereType<RegExpMatch>()
        .first;
    final official = int.parse(before.group(2)!) + 1;

    // Open the first row of group C that has no score yet (which rows are
    // scored depends on the draw) and enter a flight.
    final empty = _timeFields()
        .evaluate()
        .map((e) => e.widget as TextField)
        .firstWhere((w) => (w.controller?.text ?? '').isEmpty);
    final rowId = (empty.key! as ValueKey<String>).value.substring(
      'score-time-'.length,
    );
    final time = find.byKey(ValueKey('score-time-$rowId'));
    await pumpUntilFound(tester, time);
    await tapVisible(tester, time);
    await enterIn(tester, time, '630');
    await pumpUntilFound(tester, find.text('6:30'));
    await enterIn(tester, find.byKey(ValueKey('score-height-$rowId')), '180');
    await pumpUntilFound(tester, find.text('1 unsaved row'));

    // Saving the row makes it official, and the strip counts it.
    await tapVisible(tester, find.byKey(ValueKey('score-save-$rowId')));
    await pumpUntilFound(
      tester,
      find.text('$official of 4 entered · $official official'),
    );
    await pumpUntilFound(tester, find.text('Lock…'));
  });

  testWidgets('save all: a pending penalty removal records one reason', (
    tester,
  ) async {
    const reason = 'GliderScore import: the slip was a timer misread';
    await openMainPage(tester);
    await openContest(tester, _contest);
    await pumpUntilFound(tester, find.byKey(const ValueKey('progress-tile-5')));

    // The progress tile opens Scoring at round 5; step back to round 4, the
    // round the demo carries an applied cumulative penalty.
    await tapVisible(tester, find.byKey(const ValueKey('progress-tile-5')));
    await pumpUntilFound(tester, find.text('Round 5 of 6'));
    await tapVisible(tester, find.byKey(const ValueKey('round-picker')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('picker-item-4')));
    await tapVisible(tester, find.byKey(const ValueKey('picker-item-4')));
    await pumpUntilFound(tester, find.text('Round 4 of 6'));

    // The applied penalty sits in exactly one row of the round, in whatever
    // group the draw placed it; scan the groups until it is visible.
    for (final group in [1, 2, 3]) {
      await tapVisible(tester, find.byKey(const ValueKey('group-picker')));
      await pumpUntilFound(
        tester,
        find.byKey(ValueKey('picker-item-$group')),
      );
      await tapVisible(tester, find.byKey(ValueKey('picker-item-$group')));
      if (find.text('30 total').evaluate().isNotEmpty) break;
    }
    await pumpUntilFound(tester, find.text('30 total'));

    // Activate that row and reduce the applied cumulative penalty to 0.
    final rowKey = _rowContaining('30 total');
    final rowId = rowKey.value.substring('score-row-'.length);
    await tapVisible(tester, find.byKey(rowKey));
    await pumpUntilFound(tester, find.byKey(const ValueKey('cumulative-penalty')));
    await enterIn(tester, find.byKey(const ValueKey('cumulative-penalty')), '0');
    await pumpUntilFound(tester, find.text('Applied, then removed.'));

    // Saving the group asks for one shared reason for the pending removal.
    await tapVisible(tester, find.byKey(const ValueKey('score-save-all')));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('penalty-removal-dialog')),
    );
    // A single pending removal asks about that one pilot, not a count.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('penalty-removal-dialog')),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Text &&
              (w.data?.startsWith('Remove ') ?? false) &&
              (w.data?.endsWith("'s penalty?") ?? false),
        ),
      ),
      findsOneWidget,
    );
    await enterIn(
      tester,
      find.byKey(const ValueKey('penalty-removal-reason')),
      reason,
    );
    await tapVisible(tester, find.byKey(const ValueKey('penalty-removal-confirm')));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('scoring-context-strip')),
    );

    // The history shows the removal recorded with the reason.
    await tapVisible(tester, find.byKey(ValueKey('row-menu-$rowId')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('menu-history')));
    await tapVisible(tester, find.byKey(const ValueKey('menu-history')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('score-history-dialog')));
    await pumpUntilFound(tester, find.textContaining('Cumulative penalty removed'));
    await pumpUntilFound(tester, find.text('Reason: $reason'));
    await tapVisible(tester, find.byKey(const ValueKey('score-history-close')));
  });

  testWidgets('apply and remove a cumulative penalty, with a reason', (
    tester,
  ) async {
    await openMainPage(tester);
    await openContest(tester, _contest);
    await pumpUntilFound(tester, find.byKey(const ValueKey('progress-tile-5')));

    // The progress tile opens Scoring at round 5.
    await tapVisible(tester, find.byKey(const ValueKey('progress-tile-5')));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('scoring-context-strip')),
    );

    // The active (first unscored) row of the group is shown with its entry
    // panel; enter a flight and apply a cumulative penalty.
    final empty = _timeFields()
        .evaluate()
        .map((e) => e.widget as TextField)
        .firstWhere((w) => (w.controller?.text ?? '').isEmpty);
    final rowId = (empty.key! as ValueKey<String>).value.substring(
      'score-time-'.length,
    );
    await enterIn(tester, find.byKey(ValueKey('score-time-$rowId')), '630');
    await enterIn(tester, find.byKey(ValueKey('score-height-$rowId')), '180');
    await enterIn(tester, find.byKey(const ValueKey('cumulative-penalty')), '30');
    await pumpUntilFound(tester, find.text('−30 pts from the contest total.'));

    // Saving records the applied cumulative penalty.
    await tapVisible(tester, find.byKey(ValueKey('score-save-$rowId')));
    // The save advances to the next row, so re-activate the one just saved.
    await pumpUntilFound(tester, find.byKey(ValueKey('score-row-$rowId')));

    // The score history shows the cumulative penalty applied.
    await tapVisible(tester, find.byKey(ValueKey('row-menu-$rowId')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('menu-history')));
    await tapVisible(tester, find.byKey(const ValueKey('menu-history')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('score-history-dialog')));
    await pumpUntilFound(tester, find.textContaining('Cumulative penalty 30'));
    await tapVisible(tester, find.byKey(const ValueKey('score-history-close')));

    // Re-activate the row and remove the applied cumulative penalty.
    await tapVisible(tester, find.byKey(ValueKey('score-row-$rowId')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('cumulative-penalty')));
    await enterIn(tester, find.byKey(const ValueKey('cumulative-penalty')), '0');
    await pumpUntilFound(tester, find.text('Applied, then removed.'));

    // Saving a removal asks for a recorded reason first.
    await tapVisible(tester, find.byKey(ValueKey('score-save-$rowId')));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('penalty-removal-dialog')),
    );
    await enterIn(
      tester,
      find.byKey(const ValueKey('penalty-removal-reason')),
      'Timer slip misread on the timekeeper board',
    );
    await tapVisible(tester, find.byKey(const ValueKey('penalty-removal-confirm')));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('scoring-context-strip')),
    );

    // The history now shows the removal with its recorded reason.
    await tapVisible(tester, find.byKey(ValueKey('row-menu-$rowId')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('menu-history')));
    await tapVisible(tester, find.byKey(const ValueKey('menu-history')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('score-history-dialog')));
    await pumpUntilFound(tester, find.textContaining('Cumulative penalty removed'));
    await pumpUntilFound(
      tester,
      find.text('Reason: Timer slip misread on the timekeeper board'),
    );
  });
}
