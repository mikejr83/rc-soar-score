import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/interact.dart';
import 'support/launch_app.dart';
import 'support/participant_extras.dart';
import 'support/participant_form.dart';

/// A new person: first name, last name, email, club, city and state.
typedef _Person = (String, String, String, String, String, String);

const List<_Person> _people = [
  (
    'Zoe',
    'Whitfield',
    'zoe.whitfield@e2e.example',
    'E2E Soaring',
    'Golden',
    'CO',
  ),
  ('Milo', 'Okafor', 'milo.okafor@e2e.example', 'E2E Soaring', 'Boulder', 'CO'),
];

/// Zoe is added first and is the person the later steps look up and repeat.
const String _zoeEmail = 'zoe.whitfield@e2e.example';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // One journey for the whole participants manager and editor. The Windows
  // app allows a single instance, so each test file costs a full launch; the
  // steps below share one launch and use different people so they do not
  // depend on each other. A failure points at the step function in the trace.
  testWidgets('the participants manager and editor', (tester) async {
    await openMainPage(tester);
    await openParticipantsManager(tester);

    await _addNewParticipants(tester);
    await _searchByEmail(tester);
    await _editExistingParticipant(tester);
    await _repeatedEmailCannotBeCreated(tester);
    await _leavingWithChangesAsksFirst(tester);
    await _deleteAsksFirst(tester);
  });
}

/// New participants are added in the manager and show their details.
Future<void> _addNewParticipants(WidgetTester tester) async {
  for (final (first, last, email, club, city, state) in _people) {
    await tapVisible(tester, find.byKey(const ValueKey('add-participant')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('first-name')));

    await enterIn(tester, find.byKey(const ValueKey('first-name')), first);
    await enterIn(tester, find.byKey(const ValueKey('last-name')), last);
    await enterIn(tester, find.byKey(const ValueKey('email')), email);
    await enterIn(tester, editorField('Club'), club);
    await enterIn(tester, editorField('City'), city);
    await enterIn(tester, editorField('State/province'), state);
    await saveParticipant(tester);
  }

  for (final (first, last, email, club, _, _) in _people) {
    await searchParticipants(tester, last);
    final row = participantRow('$first $last');
    await pumpUntilFound(tester, row);
    await tapVisible(tester, row);
    await pumpUntilFound(tester, find.text(email));
    expect(find.text(club), findsWidgets);
  }
}

/// The search finds a person by email, by part of it, and finds nobody for
/// an unknown one.
Future<void> _searchByEmail(WidgetTester tester) async {
  await searchParticipants(tester, _zoeEmail);
  await pumpUntilFound(tester, participantRow('Zoe Whitfield'));

  await searchParticipants(tester, 'zoe.whitfield');
  await pumpUntilFound(tester, participantRow('Zoe Whitfield'));

  await searchParticipants(tester, 'nobody.here@e2e.example');
  await pumpUntilFound(tester, find.text('No participants match.'));
  expect(participantRow('Zoe Whitfield'), findsNothing);
}

/// An existing participant is edited and the change is shown.
Future<void> _editExistingParticipant(WidgetTester tester) async {
  // Avery Brooks is the first person of the demo roster.
  await searchParticipants(tester, 'Avery Brooks');
  final row = participantRow('Avery Brooks');
  await pumpUntilFound(tester, row);
  await tapVisible(tester, row);
  await pumpUntilFound(tester, find.text('Front Range Soaring'));

  await tapVisible(tester, find.byKey(const ValueKey('edit-participant')));
  await pumpUntilFound(tester, find.byKey(const ValueKey('first-name')));
  // Nothing changed yet, so the action bar is not shown.
  expect(find.byKey(const ValueKey('save-participant')), findsNothing);
  expect(
    tester
        .widget<TextField>(find.byKey(const ValueKey('first-name')))
        .controller!
        .text,
    'Avery',
  );

  await enterIn(
    tester,
    find.byKey(const ValueKey('email')),
    'avery.brooks@example.com',
  );
  await enterIn(tester, editorField('Club'), 'E2E Soaring Club');
  await enterIn(tester, editorField('City'), 'Evergreen');
  await saveParticipant(tester);

  await searchParticipants(tester, 'Avery Brooks');
  await tapVisible(tester, participantRow('Avery Brooks'));
  await pumpUntilFound(tester, find.text('E2E Soaring Club'));
  expect(find.text('Evergreen'), findsWidgets);
  expect(find.text('Front Range Soaring'), findsNothing);
}

/// A second person with an existing email stops at the decision: use the
/// existing person, or change the email. No separate profile can be made.
Future<void> _repeatedEmailCannotBeCreated(WidgetTester tester) async {
  await fillNewParticipant(
    tester,
    first: 'E2E',
    last: 'Twin',
    email: _zoeEmail,
  );
  await tapVisible(tester, find.byKey(const ValueKey('save-participant')));
  await pumpUntilFound(tester, find.byKey(const ValueKey('duplicate-notice')));
  expect(find.text('Someone with this email already exists'), findsOneWidget);
  expect(find.byKey(const ValueKey('create-separate')), findsNothing);

  // Use existing opens the editor of the person who already has the email.
  await tapVisible(tester, find.byKey(const ValueKey('use-existing')));
  await pumpUntilFound(
    tester,
    find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          w.key == const ValueKey('last-name') &&
          w.controller!.text == 'Whitfield',
      description: 'last name field with Whitfield',
    ),
  );
  expect(
    tester
        .widget<TextField>(find.byKey(const ValueKey('email')))
        .controller!
        .text,
    _zoeEmail,
  );
  // Nothing changed, so there is no bar to cancel from; leave by the rail.
  await tapRail(tester, 'Participants');
  await pumpUntilFound(tester, participantSearch);
  await searchParticipants(tester, 'E2E Twin');
  await pumpUntilFound(tester, find.text('No participants match.'));

  // Change the email goes back to the form; a different email saves.
  await fillNewParticipant(
    tester,
    first: 'E2E',
    last: 'Twin',
    email: _zoeEmail,
  );
  await tapVisible(tester, find.byKey(const ValueKey('save-participant')));
  await pumpUntilFound(tester, find.byKey(const ValueKey('duplicate-notice')));
  await tapVisible(tester, find.byKey(const ValueKey('change-email')));
  await pumpUntilFound(tester, find.byKey(const ValueKey('email')));
  await enterIn(
    tester,
    find.byKey(const ValueKey('email')),
    'e2e.twin@e2e.example',
  );
  await saveParticipant(tester);
  await searchParticipants(tester, 'E2E Twin');
  await pumpUntilFound(tester, participantRow('E2E Twin'));
  await searchParticipants(tester, 'Whitfield');
  await pumpUntilFound(tester, participantRow('Zoe Whitfield'));
}

/// Leaving the editor with changes asks first; Discard creates no one.
Future<void> _leavingWithChangesAsksFirst(WidgetTester tester) async {
  await fillNewParticipant(
    tester,
    first: 'E2E',
    last: 'Discarded',
    email: 'e2e.discarded@e2e.example',
  );

  // Keep editing leaves the editor and its values as they were.
  await tapVisible(tester, find.byKey(const ValueKey('cancel-participant')));
  await pumpUntilFound(tester, find.text('Discard changes?'));
  await tapVisible(tester, find.text('Keep editing'));
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.text('Discard changes?'), findsNothing);
  expect(
    tester
        .widget<TextField>(find.byKey(const ValueKey('last-name')))
        .controller!
        .text,
    'Discarded',
  );

  // Discard returns to the manager without creating the person.
  await tapVisible(tester, find.byKey(const ValueKey('cancel-participant')));
  await pumpUntilFound(tester, find.text('Discard changes?'));
  await tapVisible(tester, find.text('Discard'));
  await pumpUntilFound(tester, participantSearch);
  await searchParticipants(tester, 'Discarded');
  await pumpUntilFound(tester, find.text('No participants match.'));
}

/// Deleting asks first; Cancel keeps the person, Delete removes them.
Future<void> _deleteAsksFirst(WidgetTester tester) async {
  await addParticipant(
    tester,
    first: 'E2E',
    last: 'Deleteme',
    email: 'e2e.deleteme@e2e.example',
  );
  await selectParticipant(tester, 'E2E Deleteme');

  await tapVisible(tester, find.byTooltip('Delete E2E Deleteme'));
  await pumpUntilFound(tester, find.text('Delete participant?'));
  await tapVisible(
    tester,
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Cancel'),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.text('Delete participant?'), findsNothing);
  expect(participantRow('E2E Deleteme'), findsOneWidget);

  await tapVisible(tester, find.byTooltip('Delete E2E Deleteme'));
  await pumpUntilFound(tester, find.text('Delete participant?'));
  await tapVisible(
    tester,
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Delete'),
    ),
  );
  await pumpUntilFound(tester, find.text('No participants match.'));
  expect(participantRow('E2E Deleteme'), findsNothing);
}
