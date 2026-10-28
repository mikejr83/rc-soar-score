import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/scoring/scoring_row.dart';
import 'package:soar_score_contest/widgets/scoring/score_row_tile.dart';

import '../support/interact.dart';
import '../support/launch_app.dart';
import '../support/pump_until_gone.dart';
import 'journey.dart';

/// What the director types for one flight: digits for the time field (`630`
/// is 6:30) and the launch height in metres.
typedef Flight = ({String time, String height});

/// The flight of the pilot called [name], derived from where the name stands
/// in [JourneyContext.pilotNames], so the standings do not depend on the
/// draw: the first pilot flies the longest and launches lowest, each later
/// pilot flies 20 s less, and the last pilot flies far less than anyone.
/// [bonusSeconds] is added on a correction.
Flight flightOf(JourneyContext data, String name, {int bonusSeconds = 0}) {
  final index = data.pilotNames.indexOf(name);
  expect(index, greaterThanOrEqualTo(0), reason: '$name is not a pilot');
  final last = index == data.pilotNames.length - 1;
  final seconds = (last ? 150 : 590 - 20 * index) + bonusSeconds;
  final time = '${seconds ~/ 60}${(seconds % 60).toString().padLeft(2, '0')}';
  return (time: time, height: index == 0 ? '100' : '190');
}

Finder _key(String key) => find.byKey(ValueKey(key));

Finder _tiles() => find.byType(ScoreRowTile);

/// The tiles built right now, in tree order.
List<ScoreRowTile> _built(WidgetTester tester) =>
    tester.widgetList<ScoreRowTile>(_tiles()).toList();

/// The row of the pilot called [name] in the open group, or null when that
/// pilot is not in it. A list builds only the rows near the screen, so the
/// table is looked at from its top and, failing that, scrolled to its end,
/// where it is left.
Future<ScoringRow?> rowOf(WidgetTester tester, String name) async {
  ScoringRow? built() {
    for (final tile in _built(tester)) {
      if (tile.row.pilot.name == name) {
        return tile.row;
      }
    }
    return null;
  }

  final table = _key('score-table');
  await tester.drag(table, const Offset(0, 2000));
  await tester.pump(const Duration(milliseconds: 300));
  final top = built();
  if (top != null) {
    return top;
  }
  await tester.drag(table, const Offset(0, -2000));
  await tester.pump(const Duration(milliseconds: 300));
  // Stay where the row is built, so the caller can use it at once.
  return built();
}

/// Any row of the open group (the tree does not list them in screen order).
ScoringRow anyRow(WidgetTester tester) => _built(tester).first.row;

/// Opens Scoring at [round] and [group] with the page's own pickers, so the
/// call works from wherever the journey stands inside the contest.
Future<void> openRoundGroup(WidgetTester tester, int round, int group) async {
  if (find.byKey(const ValueKey('round-picker')).evaluate().isEmpty) {
    await tapRail(tester, 'Scoring');
    await pumpUntilFound(tester, _key('round-picker'));
  }
  await pumpUntilFound(tester, _tiles());
  if (find.text('Round $round of ${_roundCount(tester)}').evaluate().isEmpty) {
    await tapVisible(tester, _key('round-picker'));
    await pumpUntilFound(tester, _key('picker-item-$round'));
    await tapVisible(tester, _key('picker-item-$round'));
    await pumpUntilFound(tester, find.textContaining('Round $round of'));
  }
  if (find.textContaining('Group ${_letter(group)} of').evaluate().isEmpty) {
    await tapVisible(tester, _key('group-picker'));
    await pumpUntilFound(tester, _key('picker-item-$group'));
    await tapVisible(tester, _key('picker-item-$group'));
    await pumpUntilFound(
      tester,
      find.textContaining('Group ${_letter(group)} of'),
    );
  }
  await pumpUntilFound(tester, _tiles());
}

String _letter(int group) => String.fromCharCode(0x40 + group);

int _roundCount(WidgetTester tester) {
  final title = tester
      .widgetList<Text>(find.textContaining(RegExp(r'^Round \d+ of \d+$')))
      .firstOrNull;
  return int.parse(RegExp(r'of (\d+)').firstMatch(title?.data ?? '')![1]!);
}

/// Opens the group of [round] that [name] flies in and returns the group's
/// number. The draw decides which group that is, so every group is looked at.
Future<int> openGroupOf(
  WidgetTester tester,
  JourneyContext data,
  int round,
  String name,
) async {
  for (var group = 1; group <= data.groupsPerRound; group++) {
    await openRoundGroup(tester, round, group);
    if (await rowOf(tester, name) != null) {
      return group;
    }
  }
  fail('$name flies in no group of round $round.');
}

/// What to do with a pilot's row before it is saved.
typedef BeforeSave = Future<void> Function(WidgetTester tester, ScoringRow row);

/// Enters the flight of every row of the open group that has no score yet and
/// saves each one, in the order the page lists them. [only] limits it to the
/// first [only] rows. A cumulative penalty from [penalties] (by pilot name) is
/// applied with the save. Returns the names of the pilots scored.
Future<List<String>> scoreOpenRows(
  WidgetTester tester,
  JourneyContext data, {
  int? only,
  Map<String, int> penalties = const {},
}) async {
  final scored = <String>[];
  while (only == null || scored.length < only) {
    final next = await _firstOpenRow(tester);
    if (next == null) {
      break;
    }
    final id = next.id.value;
    final name = next.pilot.name;
    final flight = flightOf(data, name);
    final time = fieldWithKey('score-time-$id');
    await pumpUntilFound(tester, time);
    await tapVisible(tester, time);
    await enterIn(tester, time, flight.time);
    await enterIn(tester, fieldWithKey('score-height-$id'), flight.height);
    final penalty = penalties[name];
    if (penalty != null) {
      await pumpUntilFound(tester, _key('cumulative-penalty'));
      await enterIn(tester, _key('cumulative-penalty'), '$penalty');
      await pumpUntilFound(
        tester,
        find.text('−$penalty pts from the contest total.'),
      );
    }
    final officialBefore = _officialCount(tester);
    await tapVisible(tester, _key('score-save-$id'));
    // The strip's count, not the row, tells the save landed: saving moves on
    // to the next pilot and the saved row may have scrolled out of the list.
    await _pumpUntilOfficial(tester, officialBefore + 1, name);
    scored.add(name);
  }
  return scored;
}

/// The first built row that has no score and is not retired. A list builds
/// only the rows near the screen, so the table is scrolled once to reach the
/// rest before the group counts as done.
Future<ScoringRow?> _firstOpenRow(WidgetTester tester) async {
  ScoringRow? open() {
    for (final tile in _built(tester)) {
      if (tile.row.status == RowStatus.notEntered) {
        return tile.row;
      }
    }
    return null;
  }

  final first = open();
  if (first != null) {
    return first;
  }
  final table = find.byKey(const ValueKey('score-table'));
  await tester.drag(table, const Offset(0, -600));
  await tester.pump(const Duration(milliseconds: 300));
  final lower = open();
  await tester.drag(table, const Offset(0, 2000));
  await tester.pump(const Duration(milliseconds: 300));
  return lower;
}

/// Scores every group of [round] completely and checks the strip says so.
Future<void> scoreRound(
  WidgetTester tester,
  JourneyContext data,
  int round, {
  Map<String, int> penalties = const {},
}) async {
  for (var group = 1; group <= data.groupsPerRound; group++) {
    await openRoundGroup(tester, round, group);
    await scoreOpenRows(tester, data, penalties: penalties);
    expectGroupScored(tester);
  }
  await pumpUntilFound(tester, find.text('Round scored'));
}

/// Checks the strip counts every pilot of the group as entered and official.
void expectGroupScored(WidgetTester tester) {
  final counts = RegExp(r'^(\d+) of (\d+) entered · (\d+) official$');
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .whereType<String>()
      .map(counts.firstMatch)
      .whereType<RegExpMatch>()
      .toList();
  expect(texts, hasLength(1), reason: 'the strip shows one count');
  final m = texts.single;
  expect(m[1], m[2], reason: 'every pilot is entered');
  expect(m[3], m[2], reason: 'every score is official');
}

/// Opens the history of the row of [name] from its row menu.
Future<void> openRowHistory(WidgetTester tester, ScoringRow row) async {
  final menu = _key('row-menu-${row.id.value}');
  if (menu.evaluate().isEmpty) {
    // A list builds only the rows near the screen; saving moved on to the
    // next pilot, so go back to the top.
    await tester.drag(_key('score-table'), const Offset(0, 2000));
    await tester.pump(const Duration(milliseconds: 300));
  }
  await pumpUntilFound(tester, menu);
  await tapVisible(tester, menu);
  await pumpUntilFound(tester, _key('menu-history'));
  await tapVisible(tester, _key('menu-history'));
  await pumpUntilFound(tester, _key('score-history-dialog'));
}

Future<void> closeHistory(WidgetTester tester) async {
  await tapVisible(tester, _key('score-history-close'));
  await pumpUntilGone(tester, _key('score-history-dialog'));
}

final _stripCount = RegExp(r'^(\d+) of (\d+) entered · (\d+) official$');

/// The official count in the group's strip.
int _officialCount(WidgetTester tester) {
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final match = _stripCount.firstMatch(text.data ?? '');
    if (match != null) {
      return int.parse(match[3]!);
    }
  }
  fail('The group strip is not on screen.');
}

Future<void> _pumpUntilOfficial(
  WidgetTester tester,
  int expected,
  String name,
) async {
  final end = DateTime.now().add(const Duration(seconds: 30));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (_officialCount(tester) >= expected) {
      return;
    }
  }
  fail('The score of $name did not become official ($expected official).');
}
