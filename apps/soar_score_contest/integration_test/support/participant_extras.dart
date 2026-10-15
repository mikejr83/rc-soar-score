import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interact.dart';
import 'launch_app.dart';
import 'participant_form.dart';

/// From the main page, opens the participants manager.
Future<void> openParticipantsManager(WidgetTester tester) async {
  await tapRail(tester, 'Participants');
  await pumpUntilFound(tester, participantSearch);
}

/// Opens the new participant editor and fills first name, last name and
/// email. Does not save.
Future<void> fillNewParticipant(
  WidgetTester tester, {
  required String first,
  required String last,
  required String email,
}) async {
  await tapVisible(tester, find.byKey(const ValueKey('add-participant')));
  await pumpUntilFound(tester, find.byKey(const ValueKey('first-name')));
  await enterIn(tester, find.byKey(const ValueKey('first-name')), first);
  await enterIn(tester, find.byKey(const ValueKey('last-name')), last);
  await enterIn(tester, find.byKey(const ValueKey('email')), email);
}

/// Adds a participant through the editor and returns to the manager.
Future<void> addParticipant(
  WidgetTester tester, {
  required String first,
  required String last,
  required String email,
}) async {
  await fillNewParticipant(tester, first: first, last: last, email: email);
  await saveParticipant(tester);
}

/// Searches for [name] and selects its row, showing the detail pane.
Future<void> selectParticipant(WidgetTester tester, String name) async {
  await searchParticipants(tester, name);
  final row = participantRow(name);
  await pumpUntilFound(tester, row);
  await tapVisible(tester, row);
  await pumpUntilFound(tester, find.byKey(const ValueKey('edit-participant')));
}
