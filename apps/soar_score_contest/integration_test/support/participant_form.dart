import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interact.dart';
import 'launch_app.dart';

/// The participants manager's list search field.
Finder get participantSearch =>
    find.byKey(const ValueKey('participant-search'));

/// Narrows the participants manager's list to [text].
Future<void> searchParticipants(WidgetTester tester, String text) async {
  await enterIn(tester, participantSearch, text);
}

/// The list row of the participant called [name].
Finder participantRow(String name) =>
    find.descendant(of: find.byType(ListTile), matching: find.text(name));

/// The field of the participant editor with the label [label].
Finder editorField(String label) => find.widgetWithText(TextFormField, label);

/// Presses Save in the participant editor and waits for the participants
/// manager to show again.
Future<void> saveParticipant(WidgetTester tester) async {
  await tapVisible(tester, find.byKey(const ValueKey('save-participant')));
  await pumpUntilFound(tester, participantSearch);
}
