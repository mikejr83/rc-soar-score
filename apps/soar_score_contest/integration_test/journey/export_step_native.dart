import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';

import '../support/exchange_files.dart';
import '../support/interact.dart';
import '../support/launch_app.dart';
import 'journey.dart';

Finder _key(String key) => find.byKey(ValueKey(key));

/// Saves the journey's contest to a file from the contest list. Native only:
/// the web build holds no contest data, so it has no export, and the file
/// chooser is replaced by a recorder because a journey cannot drive it.
Future<void> exportContestToFile(
  WidgetTester tester,
  JourneyContext data,
) async {
  final saved = fakeExchangeFiles();
  await goToMainPage(tester);
  await selectContest(tester, data.contestName);
  await tapVisible(tester, _key('export-contest'));
  await pumpUntilFound(tester, _key('export-dialog'));

  // Email addresses are removed unless the director says otherwise, and
  // the dialog says the file is not encrypted.
  expect(tester.widget<CheckboxListTile>(_key('export-redact')).value, isTrue);
  expect(find.text(AppLocalizationsEn().exportNotice), findsOneWidget);

  await tapVisible(tester, _key('export-save'));
  await pumpUntilFound(
    tester,
    find.text(AppLocalizationsEn().exportSaved('${data.contestName}.rcsoar')),
  );
  expect(saved.keys, ['${data.contestName}.rcsoar']);
  final text = utf8.decode(saved.values.single);
  expect(text, contains(data.contestName));
  expect(text, contains('rcsoar'));

  // A plain export carries no log and is not a container.
  expect(saved.values.single.take(2), isNot([0x50, 0x4b]));
  expect(text, isNot(contains('app.log')));
}

/// Saves the journey's contest as an export for support: ticking it turns the
/// redaction choice off and locks it, and the file is a container with the
/// manifest, the contest and the app log.
Future<void> exportContestForSupport(
  WidgetTester tester,
  JourneyContext data,
) async {
  final saved = fakeExchangeFiles();
  await goToMainPage(tester);
  await selectContest(tester, data.contestName);
  await tapVisible(tester, _key('export-contest'));
  await pumpUntilFound(tester, _key('export-dialog'));

  expect(
    tester.widget<CheckboxListTile>(_key('export-for-support')).value,
    isFalse,
  );
  await tapVisible(tester, _key('export-for-support'));
  await tester.pumpAndSettle();
  final redact = tester.widget<CheckboxListTile>(_key('export-redact'));
  expect(redact.value, isFalse);
  expect(redact.onChanged, isNull);

  await tapVisible(tester, _key('export-save'));
  await pumpUntilFound(
    tester,
    find.text(AppLocalizationsEn().exportSaved('${data.contestName}.rcsoar')),
  );
  final archive = ZipDecoder().decodeBytes(saved.values.single);
  expect(archive.files.map((f) => f.name), [
    'manifest.json',
    'contest.json',
    'app.log',
  ]);
  expect(
    utf8.decode(archive.findFile('contest.json')!.readBytes()!),
    contains(data.contestName),
  );
  final log = utf8.decode(archive.findFile('app.log')!.readBytes()!);
  expect(log, contains('NativeBootstrap'));
}
