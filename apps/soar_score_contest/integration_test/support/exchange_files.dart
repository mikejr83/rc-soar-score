import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/platform/native_contest_exchange.dart';
import 'package:soar_score_contest/server/embedded_server.dart';
import 'package:soar_score_contest/services/exchange/contest_exchange.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import 'interact.dart';
import 'launch_app.dart';

/// A contest file as another installation would send it: made on a database
/// of its own, with ids the app under test has not seen.
Future<Uint8List> contestFromAnotherInstallation(String name) async {
  final dir = Directory.systemTemp.createTempSync('e2e_other_installation');
  final server = await startEmbeddedServer('${dir.path}/other.db');
  final client = ApiClient(
    baseUrl: server.baseUrl,
    tokenProvider: () async => server.secret,
  );
  try {
    final id = core.Id.create();
    await client.createContest(
      CreateContestRequest(
        id: id,
        name: name,
        startDateTime: DateTime.utc(2026, 5, 1),
        endDateTime: DateTime.utc(2026, 5, 2),
        timezone: 'America/Denver',
      ),
    );
    return (await NativeContestExchange(server).export(id, redact: true)).bytes;
  } finally {
    client.close();
    await server.close();
    dir.deleteSync(recursive: true);
  }
}

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
