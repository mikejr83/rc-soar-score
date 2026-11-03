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
/// the report viewer's Back (the viewer sits outside the shell), the
/// header's Contests crumb inside a contest, or the rail's Contests entry
/// elsewhere. Steps start with this so they never depend on where the
/// previous step left the screen.
Future<void> goToMainPage(WidgetTester tester) async {
  // A report opened in place is outside the shell, so neither the crumb nor
  // the rail exists there; tap its Back to pop out onto the shell first.
  final viewerBack = find.byKey(const ValueKey('viewer-back'));
  while (viewerBack.evaluate().isNotEmpty) {
    await tapVisible(tester, viewerBack);
  }
  final crumb = find.byKey(const ValueKey('breadcrumb-contests'));
  if (crumb.evaluate().isNotEmpty) {
    await tapVisible(tester, crumb);
  } else {
    await tapRail(tester, 'Contests');
  }
  await pumpUntilFound(tester, find.byType(HomePage));
  await pumpUntilFound(tester, find.byKey(const ValueKey('create-contest')));
}

/// Scrolls the list that holds the `ListTile` rows until [row] is built. A
/// list builds only the rows near the screen, and a smaller window than the
/// web run's shows fewer of them, so a row far down the list is not there to
/// find until the list is scrolled to it.
Future<void> scrollListTo(WidgetTester tester, Finder row) async {
  await pumpUntilFound(tester, find.byType(ListTile));
  if (row.evaluate().isNotEmpty) {
    return;
  }
  final list = find
      .ancestor(
        of: find.byType(ListTile).first,
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(row, 200, scrollable: list, maxScrolls: 60);
}

/// Scrolls [finder] into view, taps it and lets the app react.
///
/// `ensureVisible` can leave a widget at the very edge of its list, under a
/// pinned heading or a closing menu, or past the window's edge, and a tap
/// there lands on something else without any error. So the tap point is
/// checked: if the widget is not what a tap reaches, it is centred in its
/// scroll view, and if it still is not, the step fails here, naming what is
/// in the way, instead of timing out later on something the tap should have
/// done. A caller that taps again by design when the first tap is lost (the
/// layout shifts under it) passes `strict: false` to tap regardless.
Future<void> tapVisible(
  WidgetTester tester,
  Finder finder, {
  bool strict = true,
}) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 100));
  if (!_tapReaches(tester, finder)) {
    await Scrollable.ensureVisible(finder.evaluate().first, alignment: 0.5);
    await tester.pump(const Duration(milliseconds: 300));
  }
  final covering = strict ? _coveredBy(tester, finder) : null;
  if (covering != null) {
    fail(
      'A tap on ${finder.describeMatch(Plurality.one)} would not reach it: '
      '$covering is in the way. The window is '
      '${tester.view.physicalSize / tester.view.devicePixelRatio}.',
    );
  }
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
}

bool _tapReaches(WidgetTester tester, Finder finder) =>
    _coveredBy(tester, finder) == null;

/// What a tap at the centre of [finder] reaches instead of it, or null when
/// the tap reaches the widget (or its render object is not a box to check).
String? _coveredBy(WidgetTester tester, Finder finder) {
  final box = finder.evaluate().first.renderObject;
  if (box is! RenderBox || !box.attached || !box.hasSize) {
    return null;
  }
  final centre = box.localToGlobal(box.size.center(Offset.zero));
  final path = tester.hitTestOnBinding(centre).path.toList();
  for (final entry in path) {
    final target = entry.target;
    for (
      RenderObject? o = target is RenderObject ? target : null;
      o != null;
      o = o.parent
    ) {
      if (o == box) {
        return null;
      }
    }
  }
  final top = path.isEmpty ? null : path.first.target;
  if (top is RenderBox && top.hasSize) {
    final rect = top.localToGlobal(Offset.zero) & top.size;
    return '${top.runtimeType} at $rect (tap point $centre)';
  }
  return '${top.runtimeType} (tap point $centre)';
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
