import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/exchange/contest_exchange.dart';

import 'interact.dart';
import 'launch_app.dart';
import 'pump_until_gone.dart';

/// Replaces the system file dialogs: the chooser answers [chosen] (named
/// [chosenName]) and saves are recorded by file name. Restored after the
/// journey.
Map<String, Uint8List> fakeExchangeFiles({
  Uint8List? chosen,
  String chosenName = 'Sent.rcsoar',
}) {
  final saved = <String, Uint8List>{};
  final original = ExchangeFiles.current;
  addTearDown(() => ExchangeFiles.current = original);
  ExchangeFiles.current = ExchangeFiles(
    choose: () async => chosen == null
        ? null
        : ChosenExchangeFile(name: chosenName, bytes: chosen),
    save: (name, bytes) async {
      saved[name] = bytes;
      return name;
    },
  );
  return saved;
}

/// Selects the contest called [name] in the list, without opening it.
Future<void> selectContest(WidgetTester tester, String name) async {
  final row = find.descendant(
    of: find.byType(ListTile),
    matching: find.text(name),
  );
  await scrollListTo(tester, row);
  await pumpUntilFound(tester, row);
  await tapVisible(tester, row);
}

/// Imports the contest file the fake chooser holds, for inspection, and waits
/// until the contest is listed.
Future<void> importForInspection(WidgetTester tester, String name) async {
  await pumpUntilFound(tester, _countLine);
  final before = _listedContests(tester);
  await tapVisible(tester, find.byKey(const ValueKey('import-contest')));
  await pumpUntilFound(tester, find.byKey(const ValueKey('import-dialog')));
  await tapVisible(tester, find.byKey(const ValueKey('import-confirm')));
  await pumpUntilGone(tester, find.byKey(const ValueKey('import-dialog')));
  // The dialog closes while the import still runs, and the page keeps the old
  // rows until it reloads: wait for the count to grow before scrolling, or the
  // scroll could give up on rows that are about to be replaced.
  await pumpUntilFound(tester, _contestCount(before + 1));
  // The list is newest first and builds only the rows near its top, so an
  // imported contest with an old date sits below the window.
  final row = find.descendant(
    of: find.byType(ListTile),
    matching: find.text(name),
  );
  await scrollListTo(tester, row);
  await pumpUntilFound(tester, row);
}

/// The list's count line for [count] contests, "6 contests" or "1 contest".
Finder _contestCount(int count) =>
    find.text(count == 1 ? '1 contest' : '$count contests');

final _countPattern = RegExp(r'^(\d+) contests?$');

/// The list's count line, whatever the count.
final Finder _countLine = find.byWidgetPredicate(
  (widget) => widget is Text && _countPattern.hasMatch(widget.data ?? ''),
);

/// How many contests the list's count line says it holds.
int _listedContests(WidgetTester tester) {
  final line = tester.widget<Text>(_countLine.first);
  return int.parse(_countPattern.firstMatch(line.data!)!.group(1)!);
}
