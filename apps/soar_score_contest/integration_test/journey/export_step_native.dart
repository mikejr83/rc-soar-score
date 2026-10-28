import 'dart:convert';

import 'package:flutter/material.dart';
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
}
