import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/main.dart' as app;

/// Starts the real app (embedded server, SQLite, router) and returns once the
/// first frames are pumped. Use [pumpUntilFound] to wait for a screen.
///
/// Run through `scripts/e2e.ps1` or `scripts/e2e.sh`, which build with
/// `SOAR_SCORE_DEMO=true` and `SOAR_SCORE_DEMO_RESET=true`. The app then uses
/// `soar_score_demo.db`, recreated with the demo data for every run, so the
/// real database is never touched.
Future<void> launchApp(
  WidgetTester tester, {
  Duration initialPump = const Duration(milliseconds: 500),
}) async {
  await app.main();
  await tester.pump(initialPump);
  _capWindow(tester);
  await tester.pump(const Duration(milliseconds: 200));
}

/// The window the journeys are written for: a default 1280 x 720 window less
/// its frame. A bigger window (a maximised one, a high-resolution screen)
/// hides problems that the default window shows, so cap the size and the runs
/// look the same on every machine. A smaller window (the web run's) is left.
const _maxWindow = Size(1264, 681);

void _capWindow(WidgetTester tester) {
  final view = tester.view;
  final logical = view.physicalSize / view.devicePixelRatio;
  if (logical.width <= _maxWindow.width &&
      logical.height <= _maxWindow.height) {
    return;
  }
  view.physicalSize =
      Size(
        logical.width.clamp(0, _maxWindow.width),
        logical.height.clamp(0, _maxWindow.height),
      ) *
      view.devicePixelRatio;
  addTearDown(view.resetPhysicalSize);
}

/// Pumps frames until [finder] matches, up to [timeout]. Real startup and
/// navigation are asynchronous (server, database, auth restore), so
/// `pumpAndSettle` can return before the screen is there. On timeout the
/// failure lists the texts on screen, to show where the app actually is.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  final texts = find
      .byType(Text)
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .whereType<String>()
      .toList();
  fail('Timed out waiting for $finder. On screen: $texts');
}
