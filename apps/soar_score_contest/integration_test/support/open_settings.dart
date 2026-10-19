import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/pages/settings_page.dart';

import 'interact.dart';
import 'launch_app.dart';

/// Opens Settings from the account control at the bottom of the rail: a menu
/// when there is an account or the offline app, a gear otherwise.
Future<void> openSettings(WidgetTester tester) async {
  final menu = find.byKey(const ValueKey('account-menu'));
  if (menu.evaluate().isNotEmpty) {
    await tapVisible(tester, menu);
    await pumpUntilFound(tester, find.text('Settings'));
    await tapVisible(tester, find.text('Settings'));
  } else {
    await tapVisible(tester, find.byKey(const ValueKey('settings-button')));
  }
  await pumpUntilFound(tester, find.byType(SettingsPage));
}
