import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_contest/services/reports/report_launcher.dart';

void main() {
  testWidgets('InPlaceReportLauncher navigates this window with back=1', (
    tester,
  ) async {
    LaunchOutcome? outcome;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  outcome = await const InPlaceReportLauncher().open(
                    context,
                    '/viewer?x=1',
                  ),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/viewer',
          builder: (context, state) =>
              Text('viewer back=${state.uri.queryParameters['back']}'),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(outcome, LaunchOutcome.inPlace);
    expect(find.text('viewer back=1'), findsOneWidget);
  });

  test('only the E2E build opens reports in place', () {
    expect(ReportLaunchers.forBuild(e2e: true), isA<InPlaceReportLauncher>());
    expect(
      ReportLaunchers.forBuild(e2e: false),
      isNot(isA<InPlaceReportLauncher>()),
    );
    // This test run is not an E2E build.
    expect(ReportLaunchers.current, isNot(isA<InPlaceReportLauncher>()));
  });
}
