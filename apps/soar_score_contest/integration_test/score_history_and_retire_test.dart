import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:soar_score_contest/widgets/scoring/score_row_tile.dart';

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

/// The row menu of the pilot whose row shows [text] (for example a time).
/// The widget tree does not list the rows in screen order once a row is open,
/// so `.first` is not the first row.
Finder _rowMenuOf(String text) => find.descendant(
  of: find.ancestor(
    of: find.text(text).first,
    matching: find.byType(ScoreRowTile),
  ),
  matching: _keyed('row-menu-'),
);

/// Scrolls the score table back to its top when the row [finder] matches has
/// scrolled out of the list (a list builds only the rows near the screen).
Future<void> _scrollToRow(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) {
    return;
  }
  await tester.drag(
    find.byKey(const ValueKey('score-table')),
    const Offset(0, 2000),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

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
    await pumpUntilFound(tester, _field('score-time-'));

    // The widget tree does not list the rows in screen order once a row is
    // open, so the first row is followed by its id, not by `.first`.
    final id =
        (_field('score-time-').first.evaluate().first.widget.key!
                as ValueKey<String>)
            .value
            .substring('score-time-'.length);
    final time = fieldWithKey('score-time-$id');
    final save = find.byKey(ValueKey('score-save-$id'));

    // Enter a flight on the first row and save it.
    await tapVisible(tester, time);
    await enterIn(tester, time, '630');
    await enterIn(tester, fieldWithKey('score-height-$id'), '180');
    await pumpUntilFound(tester, find.text('1 unsaved row'));
    await tapVisible(tester, save);
    await pumpUntilFound(tester, find.textContaining('1 official'));

    // Correct it: the second save is the next revision. Opening the row again
    // is a tap on it, in case saving moved on to the next pilot.
    if (time.evaluate().isEmpty) {
      final row = find.byKey(ValueKey('score-row-$id'));
      await _scrollToRow(tester, row);
      await tapVisible(tester, row);
      await pumpUntilFound(tester, time);
    }
    await tapVisible(tester, time);
    await enterIn(tester, time, '640');
    await pumpUntilFound(tester, find.text('1 unsaved row'));
    await tapVisible(tester, save);
    await pumpUntilGone(tester, find.text('1 unsaved row'));

    // The history lists both revisions and the reason of the correction.
    final menu = find.byKey(ValueKey('row-menu-$id'));
    await _scrollToRow(tester, menu);
    await tapVisible(tester, menu);
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
    await pumpUntilFound(tester, find.text('Not entered'));
    await tapVisible(tester, _rowMenuOf('Not entered'));
    await pumpUntilFound(tester, find.byKey(const ValueKey('menu-retire')));
    await tapVisible(tester, find.byKey(const ValueKey('menu-retire')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('retire-dialog')));
    expect(find.textContaining('flights instead of'), findsWidgets);
    await tapVisible(tester, find.byKey(const ValueKey('retire-confirm')));
    await pumpUntilFound(tester, find.text('Retired'));
    expect(find.text('Retired from round 1'), findsOneWidget);
  });
}
