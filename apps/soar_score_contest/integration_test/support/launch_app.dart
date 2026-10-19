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
