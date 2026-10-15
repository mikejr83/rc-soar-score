import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interact.dart';
import 'launch_app.dart';

/// From the contest list, selects the contest called [name] and opens it with
/// the detail pane's primary button (Open, Continue or View, by lifecycle
/// state). Waits for the contest rail.
Future<void> openContest(WidgetTester tester, String name) async {
  // The name shows in the list row and, on wide windows, in the detail
  // pane, so target the row.
  final row = find.descendant(
    of: find.byType(ListTile),
    matching: find.text(name),
  );
  await pumpUntilFound(tester, row);
  await tapVisible(tester, row);

  final open = find.descendant(
    of: find.byType(FilledButton),
    matching: find.byWidgetPredicate(
      (w) => w is Text && const {'Open', 'Continue', 'View'}.contains(w.data),
      description: 'Text Open, Continue or View',
    ),
  );
  await pumpUntilFound(tester, open);
  await tapVisible(tester, open);
  await pumpUntilFound(tester, find.text('Workspace'));
}

/// Opens the contest rail's Configuration page and waits for its counts.
Future<void> openConfiguration(WidgetTester tester) async {
  await tapRail(tester, 'Configuration');
  await pumpUntilFound(tester, find.text('Scoring pilots'));
}
