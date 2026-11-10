import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/exchange/contest_exchange.dart';

import 'interact.dart';
import 'launch_app.dart';

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
  await tapVisible(tester, find.byKey(const ValueKey('import-contest')));
  await pumpUntilFound(tester, find.byKey(const ValueKey('import-dialog')));
  await tapVisible(tester, find.byKey(const ValueKey('import-confirm')));
  await pumpUntilFound(
    tester,
    find.descendant(of: find.byType(ListTile), matching: find.text(name)),
  );
}
