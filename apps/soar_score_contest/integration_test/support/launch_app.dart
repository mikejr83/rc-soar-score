import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/main.dart' as app;

/// Starts the real app (embedded server, SQLite, router) and waits for the
/// first frame to settle.
///
/// Run through `scripts/e2e.ps1` or `scripts/e2e.sh`, which build with
/// `SOAR_SCORE_DEMO=true` and `SOAR_SCORE_DEMO_RESET=true`. The app then uses
/// `soar_score_demo.db`, recreated with the demo data for every run, so the
/// real database is never touched.
Future<void> launchApp(WidgetTester tester) async {
  await app.main();
  await tester.pumpAndSettle(const Duration(seconds: 1));
}
