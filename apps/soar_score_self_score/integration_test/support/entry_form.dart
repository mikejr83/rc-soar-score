import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'launch_app.dart';

/// Fills the open entry form. [time] is typed the way a pilot types it
/// ("900" is 9:00).
Future<void> fillEntry(
  WidgetTester tester, {
  String time = '900',
  String height = '45',
}) async {
  await tester.enterText(await fieldFor(tester, 'Time flown'), time);
  await tester.enterText(await fieldFor(tester, 'Launch height (m)'), height);
  await tester.pump(const Duration(milliseconds: 300));
  await chooseLanding(tester);
}

/// Picks the first landing, whether the table is a short sheet or a search.
Future<void> chooseLanding(WidgetTester tester) async {
  final sheet = find.text('Choose landing');
  if (sheet.evaluate().isNotEmpty) {
    await tapVisible(tester, sheet);
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    // A sheet row is a tile with the result's label and points.
    await tester.tap(
      find
          .descendant(
            of: find.byType(DraggableScrollableSheet),
            matching: find.byType(InkWell),
          )
          .at(1),
    );
    await tester.pump(const Duration(milliseconds: 300));
    return;
  }
  // A long table is a search field: the third text field, after time and
  // height. Typing shows matches as tiles.
  await scrollTo(tester, find.byType(TextField).at(2));
  await tester.enterText(find.byType(TextField).at(2), '50');
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.byType(ListTile).first);
  await tester.pump(const Duration(milliseconds: 300));
}
