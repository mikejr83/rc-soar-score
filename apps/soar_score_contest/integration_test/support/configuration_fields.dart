import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interact.dart';

/// The row of the configuration page's setting [key], for example
/// `decimal_places`.
Finder settingField(String key) => find.byKey(ValueKey('field-$key'));

/// The value selected in the segmented setting [key].
Object segmentedValue(WidgetTester tester, String key) {
  final button = tester.widget<SegmentedButton<Object>>(
    find.descendant(
      of: settingField(key),
      matching: find.byType(SegmentedButton<Object>),
    ),
  );
  return button.selected.single;
}

/// Taps the segment labelled [label] of the segmented setting [key].
Future<void> tapSegment(WidgetTester tester, String key, String label) =>
    tapVisible(
      tester,
      find.descendant(of: settingField(key), matching: find.text(label)),
    );

/// Whether the toggle setting [key] is on.
bool toggleValue(WidgetTester tester, String key) => tester
    .widget<Switch>(
      find.descendant(of: settingField(key), matching: find.byType(Switch)),
    )
    .value;

/// Flips the toggle setting [key].
Future<void> flipToggle(WidgetTester tester, String key) => tapVisible(
  tester,
  find.descendant(of: settingField(key), matching: find.byType(Switch)),
);

/// The saved revision number shown at the top of the configuration page.
int savedRevision(WidgetTester tester) {
  final match = find.textContaining(RegExp(r'^Configuration revision \d+$'));
  final text = (match.evaluate().first.widget as Text).data!;
  return int.parse(text.split(' ').last);
}
