import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_self_score/main.dart' as app;

/// Starts the real app (hosted API client, guest session in browser storage,
/// router) and returns once the first frames are pumped.
///
/// Run through `scripts/e2e-score.sh` (or `e2e-score.ps1`), which builds the
/// web app against the E2E server (`SOAR_SCORE_API_BASE_URL`).
Future<void> launchApp(WidgetTester tester) async {
  app.main();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Pumps frames until [finder] matches, up to [timeout]. Real navigation and
/// API calls are asynchronous, so `pumpAndSettle` can return before the screen
/// is there. On timeout the failure lists the texts on screen.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder. On screen: ${screenTexts()}');
}

/// The texts on screen, for failure messages.
List<String> screenTexts() => find
    .byType(Text)
    .evaluate()
    .map((e) => (e.widget as Text).data)
    .whereType<String>()
    .toList();

/// Scrolls [finder] into view (a long page builds its rows lazily), then
/// taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await scrollTo(tester, finder);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(finder.first);
  await tester.pump(const Duration(milliseconds: 200));
}

/// Scrolls the page until [finder] is built and on screen.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final scrollable = find.byType(Scrollable).first;
    try {
      await tester.scrollUntilVisible(finder, -300, scrollable: scrollable);
    } on StateError {
      await tester.scrollUntilVisible(finder, 300, scrollable: scrollable);
    }
  }
  await tester.ensureVisible(finder.first);
  await tester.pump(const Duration(milliseconds: 100));
}

/// The text field of the entry row labelled [label] (time, height, penalty),
/// scrolled into view. The form builds its rows lazily, so a field is looked
/// up through its label, never by position.
Future<Finder> fieldFor(WidgetTester tester, String label) async {
  final labelFinder = find.text(label);
  await scrollTo(tester, labelFinder);
  Element? column;
  tester.element(labelFinder.first).visitAncestorElements((element) {
    if (element.widget is Column) {
      column = element;
      return false;
    }
    return true;
  });
  final found = column;
  if (found == null) fail('No row around the label "$label".');
  return find.descendant(
    of: find.byElementPredicate((e) => e == found),
    matching: find.byType(TextField),
  );
}
