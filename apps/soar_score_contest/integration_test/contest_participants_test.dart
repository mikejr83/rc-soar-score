import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/open_demo_contest.dart';

/// A ready demo contest: 14 pilots and a drawn matrix, no scores.
const _contest = 'Front Range F5J Open';

Finder _classField() => find.descendant(
  of: find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('class-'),
    description: 'a class cell',
  ),
  matching: find.byType(TextField),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // One test per file: `launchApp` starts the real app, which holds the demo
  // database and the embedded server's port for the life of the process.
  testWidgets('Participants page: list, edit a class, save, discard', (
    tester,
  ) async {
    await openMainPage(tester);
    await openContest(tester, _contest);

    // The rail's Participants entry opens the stored list, not the wizard's.
    await tapRail(tester, 'Participants');
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('participants-count')),
    );
    expect(find.textContaining('pilots'), findsWidgets);

    // Save is always there, off, with its reason.
    final save = find.byKey(const ValueKey('save-participants'));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    expect(find.text('No changes to save.'), findsOneWidget);

    // Editing a class marks the row and turns Save on.
    await enterIn(tester, _classField().first, 'Zz Class');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 300));
    await pumpUntilFound(tester, find.text('Unsaved changes to 1 participant'));
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);

    // Discard puts the saved value back.
    await tapVisible(
      tester,
      find.byKey(const ValueKey('discard-participants')),
    );
    await pumpUntilFound(tester, find.text('No changes to save.'));

    // Save stores the change and says so.
    await enterIn(tester, _classField().first, 'Zz Class');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 300));
    await pumpUntilFound(tester, find.text('Unsaved changes to 1 participant'));
    await tapVisible(tester, save);
    await pumpUntilFound(tester, find.text('1 participant saved.'));
    await pumpUntilFound(tester, find.text('No changes to save.'));
    expect(
      tester.widget<TextField>(_classField().first).controller!.text,
      'Zz Class',
    );
  });
}
