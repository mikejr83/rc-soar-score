import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:soar_score_contest/l10n/app_localizations_en.dart';

import 'support/exchange_files.dart';
import 'support/interact.dart';
import 'support/launch_app.dart';

const _contest = 'Front Range F5J Open';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The web build holds no contest data, so it has no export; the file chooser
  // is replaced by a recorder because a journey cannot drive it.
  testWidgets('a director exports a contest to a file (#214, native)', (
    tester,
  ) async {
    final saved = fakeExchangeFiles();

    await openMainPage(tester);
    await selectContest(tester, _contest);
    await tapVisible(tester, find.byKey(const ValueKey('export-contest')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('export-dialog')));

    // Email addresses are removed unless the director says otherwise, and the
    // dialog says the file is not encrypted.
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const ValueKey('export-redact')))
          .value,
      isTrue,
    );
    expect(find.text(AppLocalizationsEn().exportNotice), findsOneWidget);

    await tapVisible(tester, find.byKey(const ValueKey('export-save')));
    await pumpUntilFound(
      tester,
      find.text(AppLocalizationsEn().exportSaved('$_contest.rcsoar')),
    );

    expect(saved.keys, ['$_contest.rcsoar']);
    final text = utf8.decode(saved.values.single);
    expect(text, contains(_contest));
    expect(text, contains('rcsoar'));
  }, skip: kIsWeb);
}
