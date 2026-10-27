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
    await continueFromLanding(tester);
  }
  await pumpUntilFound(tester, find.byType(HomePage));
}

/// Taps the landing page's way in. Windows offers "Continue offline"; the web
/// test build is signed in already (`E2eSignedInSession`) and offers
/// "Continue".
Future<void> continueFromLanding(WidgetTester tester) async {
  final offline = find.text('Continue offline');
  await tester.tap(
    offline.evaluate().isNotEmpty ? offline : find.text('Continue'),
  );
}

/// Goes back to the main page (the contest list) from wherever the app is:
/// the header's Contests crumb inside a contest, the rail's Contests entry
/// elsewhere. Steps start with this so they never depend on where the
/// previous step left the screen.
Future<void> goToMainPage(WidgetTester tester) async {
  final crumb = find.byKey(const ValueKey('breadcrumb-contests'));
  if (crumb.evaluate().isNotEmpty) {
    await tapVisible(tester, crumb);
  } else {
    await tapRail(tester, 'Contests');
  }
  await pumpUntilFound(tester, find.byType(HomePage));
  await pumpUntilFound(tester, find.byKey(const ValueKey('create-contest')));
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

/// The `TextField` with [key]: the keyed widget itself or the one inside the
/// keyed widget.
Finder fieldWithKey(String key) {
  final keyed = find.byKey(ValueKey(key));
  final widgets = keyed.evaluate();
  if (widgets.isNotEmpty && widgets.first.widget is TextField) {
    return keyed;
  }
  return find.descendant(of: keyed, matching: find.byType(TextField));
}

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
