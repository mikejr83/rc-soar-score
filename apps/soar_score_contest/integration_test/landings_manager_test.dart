import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';

/// The landings manager's list row of the table called [name].
Finder _landingRow(String name) =>
    find.descendant(of: find.byType(ListTile), matching: find.text(name));

Finder _key(String key) => find.byKey(ValueKey(key));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a landing table is created, copied and deleted', (tester) async {
    await openMainPage(tester);
    await tapRail(tester, 'Landings');
    await pumpUntilFound(tester, find.text('Landings'));

    // A system table is read-only: copy is offered, delete is locked.
    final system = _landingRow('F5J Standard Landing Table');
    await pumpUntilFound(tester, system);
    await tapVisible(tester, system);
    await pumpUntilFound(tester, _key('landing-locked-notice'));
    expect(_key('delete-landing'), findsNothing);
    expect(_key('delete-landing-locked'), findsOneWidget);
    expect(_key('copy-landing'), findsOneWidget);

    // Create a new table with two entries.
    await tapVisible(tester, _key('new-landing'));
    await pumpUntilFound(tester, _key('landing-name'));
    expect(find.text('New landing table'), findsOneWidget);

    // Saving the empty form is refused with inline messages.
    await tapVisible(tester, _key('save-landing'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Name is required.'), findsOneWidget);
    expect(find.text('Label is required.'), findsOneWidget);
    expect(find.text('Points is required.'), findsOneWidget);

    await enterIn(tester, _key('landing-name'), 'E2E Club Table');
    await tapVisible(tester, _key('landing-unit'));
    await pumpUntilFound(tester, find.text('Meters'));
    await tapVisible(tester, find.text('Meters').last);
    await enterIn(tester, _key('entry-label-0'), 'Inside 1 m');
    await enterIn(tester, _key('entry-points-0'), '30');
    await tapVisible(tester, _key('add-landing-entry'));
    await pumpUntilFound(tester, _key('entry-label-1'));
    await enterIn(tester, _key('entry-label-1'), 'Inside 5 m');
    await enterIn(tester, _key('entry-points-1'), '15');
    await tapVisible(tester, _key('save-landing'));

    // Back on the list, the new table is "Yours" with its two entries.
    final created = _landingRow('E2E Club Table');
    await pumpUntilFound(tester, created);
    expect(find.text('Yours · Meters · 2 entries'), findsOneWidget);
    await tapVisible(tester, created);
    await pumpUntilFound(tester, find.text('Inside 5 m'));
    expect(find.text('Inside 1 m'), findsOneWidget);
    expect(_key('landing-locked-notice'), findsNothing);
    expect(_key('delete-landing'), findsOneWidget);

    // Copy it: the form starts filled, a third entry is added.
    await tapVisible(tester, _key('copy-landing'));
    await pumpUntilFound(tester, _key('entry-label-1'));
    expect(find.text('New landing table from a copy'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(_key('landing-name')).controller!.text,
      'Copy of E2E Club Table',
    );
    await enterIn(tester, _key('landing-name'), 'E2E Club Table v2');
    await tapVisible(tester, _key('add-landing-entry'));
    await pumpUntilFound(tester, _key('entry-label-2'));
    await enterIn(tester, _key('entry-label-2'), 'Touch and go');
    await enterIn(tester, _key('entry-points-2'), '5');
    await tapVisible(tester, _key('save-landing'));

    final copy = _landingRow('E2E Club Table v2');
    await pumpUntilFound(tester, copy);
    expect(_landingRow('E2E Club Table'), findsOneWidget);
    await tapVisible(tester, copy);
    await pumpUntilFound(tester, find.text('Touch and go'));
    expect(find.text('Inside 1 m'), findsOneWidget);

    // Leaving a form with changes asks first; keep editing, then discard.
    await tapVisible(tester, _key('copy-landing'));
    await pumpUntilFound(tester, _key('landing-name'));
    await enterIn(tester, _key('landing-name'), 'E2E Abandoned');
    await tapVisible(tester, _key('cancel-landing'));
    await pumpUntilFound(tester, find.text('Discard changes?'));
    await tapVisible(tester, find.text('Keep editing'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_key('landing-name'), findsOneWidget);
    await tapVisible(tester, _key('cancel-landing'));
    await pumpUntilFound(tester, find.text('Discard changes?'));
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Discard'));
    await pumpUntilFound(tester, _landingRow('E2E Club Table v2'));
    expect(_landingRow('E2E Abandoned'), findsNothing);

    // Delete both of our tables, each after the confirm dialog.
    for (final name in ['E2E Club Table v2', 'E2E Club Table']) {
      await tapVisible(tester, _landingRow(name));
      await pumpUntilFound(tester, _key('delete-landing'));
      await tapVisible(tester, _key('delete-landing'));
      await pumpUntilFound(tester, find.text('Delete landing table?'));
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Delete'));
      // The row goes once the list reloads.
      final end = DateTime.now().add(const Duration(seconds: 30));
      while (_landingRow(name).evaluate().isNotEmpty &&
          DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(_landingRow(name), findsNothing);
    }
    expect(_landingRow('F5J Standard Landing Table'), findsOneWidget);
  });
}
