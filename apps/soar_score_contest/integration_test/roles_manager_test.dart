import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';

/// The list row of the role called [name]; the detail pane repeats the name.
Finder _row(String name) =>
    find.descendant(of: find.byType(ListTile), matching: find.text(name));

/// Types [name] into the role name dialog and confirms it.
Future<void> _confirmName(WidgetTester tester, String name) async {
  final field = find.byKey(const ValueKey('role-name-field'));
  await pumpUntilFound(tester, field);
  await enterIn(tester, field, name);
  await tapVisible(tester, find.byKey(const ValueKey('role-name-confirm')));
  await pumpUntilFound(tester, find.byType(ListTile));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a role is created, renamed and deleted', (tester) async {
    await openMainPage(tester);
    await tapRail(tester, 'Roles');
    await pumpUntilFound(tester, _row('Pilot'));

    // System roles are protected: no Rename or Delete.
    await tapVisible(tester, _row('Pilot'));
    await pumpUntilFound(tester, find.text('System role'));
    expect(find.byKey(const ValueKey('rename-role')), findsNothing);
    expect(find.byKey(const ValueKey('delete-role')), findsNothing);

    // Create.
    await tapVisible(tester, find.byKey(const ValueKey('new-role')));
    await _confirmName(tester, 'E2E Scorer');
    await pumpUntilFound(tester, _row('E2E Scorer'));
    expect(find.byKey(const ValueKey('rename-role')), findsOneWidget);

    // Rename.
    await tapVisible(tester, find.byKey(const ValueKey('rename-role')));
    await _confirmName(tester, 'E2E Timekeeper');
    await pumpUntilFound(tester, _row('E2E Timekeeper'));
    expect(_row('E2E Scorer'), findsNothing);

    // Delete, after the confirmation.
    await tapVisible(tester, _row('E2E Timekeeper'));
    await tapVisible(tester, find.byKey(const ValueKey('delete-role')));
    await pumpUntilFound(tester, find.text('Delete role?'));
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Delete'));
    for (
      var i = 0;
      i < 50 && _row('E2E Timekeeper').evaluate().isNotEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(_row('E2E Timekeeper'), findsNothing);
    expect(_row('Pilot'), findsOneWidget);
  });
}
