import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/widgets/matrix/pilot_row_tile.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/matrix_test_support.dart';

/// Helpers for the tests of moving a pilot from the matrix page (#263). The fixture: round 1 is
/// {1,2} {3,4}, round 2 is {1,3} {2,4}; pilots 1 and 3 are teammates, so are
/// 2 and 4.
MatrixServer moveServer({
  bool lanes = false,
  Contest? contest,
  Set<(int, int)> lockedGroups = const {},
  RoundStatus round2Status = RoundStatus.open,
  bool protection = false,
}) => MatrixServer(
  contest: contest ?? matrixContest(state: LifecycleState.running),
  configuration: matrixConfiguration({
    if (lanes) 'lane_mode': 'Random',
    'teams_enabled': true,
    'team_pilot_count': 2,
    if (protection) 'team_protection': true,
  }),
  matrix: drawnMatrix(
    lanes: lanes,
    lockedGroups: lockedGroups,
    round2Status: round2Status,
  ),
);

Finder tileOf(String name, int round) => find.byWidgetPredicate(
  (w) => w is PilotRowTile && w.slot.pilot.name == name && w.round == round,
  description: '$name in round $round',
);

Finder keyOf(String key) => find.byKey(ValueKey(key));

Future<void> settle(WidgetTester tester) => tester.pumpAndSettle();

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await settle(tester);
}

/// Selects [name], opens the pilot actions of the tile in [round] and picks
/// Move.
Future<void> openMove(WidgetTester tester, String name, int round) async {
  await tapAndSettle(tester, tileOf(name, round));
  await tapAndSettle(
    tester,
    find.descendant(of: tileOf(name, round), matching: keyOf('pilot-actions')),
  );
  await tapAndSettle(tester, keyOf('pilot-action-move'));
}

Future<void> enterReason(WidgetTester tester, String text) async {
  await tester.enterText(keyOf('move-reason'), text);
  await tester.pump();
}

/// The text under the group row [letter] of the move dialog.
String? noteOf(WidgetTester tester, String letter) {
  final note = keyOf('move-note-$letter');
  return note.evaluate().isEmpty ? null : tester.widget<Text>(note).data;
}

String markOf(WidgetTester tester, String letter) =>
    tester.widget<Text>(keyOf('move-mark-$letter')).data!;

bool groupEnabled(WidgetTester tester, String letter) =>
    tester.widget<ListTile>(keyOf('move-group-$letter')).enabled;
