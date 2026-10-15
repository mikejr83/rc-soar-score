import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/pages/home_page.dart';
import 'package:soar_score_contest/pages/landing_page.dart';

import 'launch_app.dart';

/// Starts the app and gets to the main page (the contest list): through
/// Continue offline when the landing page shows, directly when a restored
/// sign-in sent the router there.
Future<void> openMainPage(WidgetTester tester) async {
  await launchApp(tester);
  await pumpUntilFound(
    tester,
    find.byWidgetPredicate(
      (w) => w is LandingPage || w is HomePage,
      description: 'LandingPage or HomePage',
    ),
  );
  if (find.byType(LandingPage).evaluate().isNotEmpty) {
    await tester.tap(find.text('Continue offline'));
  }
  await pumpUntilFound(tester, find.byType(HomePage));
}

/// Scrolls [finder] into view, taps it and lets the app react.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
}

/// Taps the destination called [label] in the navigation rail.
Future<void> tapRail(WidgetTester tester, String label) => tapVisible(
  tester,
  find
      .descendant(of: find.byType(NavigationRail), matching: find.text(label))
      .first,
);

/// Replaces the text of the field [field] (a `TextField` or the field
/// containing one).
Future<void> enterIn(WidgetTester tester, Finder field, String text) async {
  await tester.ensureVisible(field);
  await tester.pump(const Duration(milliseconds: 100));
  // Focus the field first: without it enterText can be dropped once another
  // widget (a tapped list row) had the focus.
  await tester.tap(field);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 200));
}

/// The `TextField` inside the widget with [key].
Finder fieldWithKey(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(TextField),
);

/// The number in the configuration page's count tile called [label], for
/// example `Scoring pilots`.
int configurationCount(WidgetTester tester, String label) {
  final columns = find
      .ancestor(of: find.text(label), matching: find.byType(Column))
      .evaluate();
  for (final column in columns) {
    final texts = find
        .descendant(
          of: find.byElementPredicate((element) => element == column),
          matching: find.byType(Text),
        )
        .evaluate()
        .toList();
    if (texts.length == 2) {
      return int.parse((texts.first.widget as Text).data!);
    }
  }
  fail('No count tile called "$label" on screen.');
}
