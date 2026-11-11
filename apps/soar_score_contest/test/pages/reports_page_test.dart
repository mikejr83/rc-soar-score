import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/pages/contest/reports_page.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/services/reports/report_kind.dart';
import 'package:soar_score_contest/services/reports/report_launcher.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../support/fake_report_launcher.dart';
import '../support/matrix_test_support.dart';
import '../support/next_step_widget_support.dart';
import '../support/workspace_facts_support.dart';

Map<(int, int), DateTime> _scored(int rounds) => {
  for (var r = 1; r <= rounds; r++)
    for (var p = 1; p <= 4; p++) (r, p): at(r * 10 + p),
};

WorkspaceServer _server({
  CurrentMatrix? matrix,
  Map<(int, int), DateTime> scored = const {},
  LifecycleState state = LifecycleState.running,
}) => WorkspaceServer(
  state: state,
  configuration: matrixConfiguration(),
  matrix: matrix,
  scores: matrix == null ? null : scoresFor(matrix, scored),
);

Future<GoRouter> _pump(
  WidgetTester tester,
  WorkspaceServer server, {
  Size size = const Size(1280, 1400),
  String contestId = matrixContestId,
  ReportLauncher? launcher,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: contestReportsPath(matrixContestId),
    routes: [
      GoRoute(
        path: contestReportsPath(matrixContestId),
        builder: (context, state) => Scaffold(
          body: ContestReportsPage(
            contestId: contestId,
            launcher: launcher ?? FakeReportLauncher(),
          ),
        ),
      ),
      for (final entry in {
        contestMatrixPath(matrixContestId): 'Matrix stub',
        contestScoringPath(matrixContestId): 'Scoring stub',
        homePath: 'Home stub',
      }.entries)
        GoRoute(path: entry.key, builder: (_, _) => Text(entry.value)),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ApiClientInherited(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient(server.handle),
      ),
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
  return router;
}

Finder _open(String key) => find.byKey(ValueKey('report-open-$key'));

bool _enabled(WidgetTester tester, String key) =>
    tester.widget<ButtonStyleButton>(_open(key)).onPressed != null;

void main() {
  testWidgets('lays the cards out in two columns when expanded, one below', (
    tester,
  ) async {
    final server = _server(matrix: drawnMatrix(), scored: _scored(2));
    await _pump(tester, server);
    final matrixCard = tester.getTopLeft(
      find.byKey(const ValueKey('report-card-matrix')),
    );
    final sheetCard = tester.getTopLeft(
      find.byKey(const ValueKey('report-card-sheet')),
    );
    expect(sheetCard.dy, matrixCard.dy);
    expect(sheetCard.dx, greaterThan(matrixCard.dx));

    await _pump(tester, server, size: const Size(700, 1800));
    final narrowMatrix = tester.getTopLeft(
      find.byKey(const ValueKey('report-card-matrix')),
    );
    final narrowSheet = tester.getTopLeft(
      find.byKey(const ValueKey('report-card-sheet')),
    );
    expect(narrowSheet.dx, narrowMatrix.dx);
    expect(narrowSheet.dy, greaterThan(narrowMatrix.dy));
  });

  testWidgets('opening the reports page asks the API once', (tester) async {
    final server = _server(matrix: drawnMatrix(), scored: _scored(2));
    await _pump(tester, server);

    expect(server.reportDataRequests, hasLength(1));
    expect(server.reportDataRequests.single.queryParameters, {
      'include': 'facts',
    });
  });

  testWidgets('fits a compact window with large text and every warning', (
    tester,
  ) async {
    final scored = _scored(2)
      ..remove((2, 3))
      ..remove((2, 4));
    await _pump(
      tester,
      _server(
        matrix: drawnMatrix(config: const {'team_protection': true}),
        scored: scored,
      ),
      size: const Size(400, 900),
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('report-card-cards')), findsOneWidget);
  });

  testWidgets('no matrix: every Open is disabled with a reason and a link', (
    tester,
  ) async {
    final router = await _pump(tester, _server());

    for (final key in ['standings', 'matrix', 'sheet', 'cards']) {
      expect(_enabled(tester, key), isFalse, reason: key);
    }
    expect(find.text('The matrix has not been drawn.'), findsNWidgets(3));
    expect(find.text('No scores have been entered yet.'), findsOneWidget);
    expect(find.text('No standings yet'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('reports-fact-matrix')),
        matching: find.text('No matrix drawn'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('report-reason-matrix')),
        matching: find.text('Open Matrix'),
      ),
    );
    await tester.pumpAndSettle();
    expect(router.state.uri.path, contestMatrixPath(matrixContestId));
  });

  testWidgets('no scores: standings unavailable, documents open', (
    tester,
  ) async {
    final router = await _pump(tester, _server(matrix: drawnMatrix()));

    expect(_enabled(tester, 'standings'), isFalse);
    expect(_enabled(tester, 'matrix'), isTrue);
    expect(find.text('No scores have been entered yet.'), findsOneWidget);

    await tester.tap(find.text('Open Scoring'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, contestScoringPath(matrixContestId));
  });

  testWidgets('missing scores warn on standings and keep Open enabled', (
    tester,
  ) async {
    final scored = _scored(2)
      ..remove((2, 3))
      ..remove((2, 4));
    final router = await _pump(
      tester,
      _server(matrix: drawnMatrix(), scored: scored),
    );

    expect(_enabled(tester, 'standings'), isTrue);
    expect(
      find.textContaining('2 pilots have no score in round 2.'),
      findsOneWidget,
    );
    expect(find.text('Preliminary'), findsOneWidget);

    await tester.tap(find.text('Open Scoring'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, contestScoringPath(matrixContestId));
    expect(router.state.uri.queryParameters['round'], '2');
  });

  testWidgets('a completed contest reads as final and keeps reports open', (
    tester,
  ) async {
    await _pump(
      tester,
      _server(
        matrix: drawnMatrix(),
        scored: _scored(2),
        state: LifecycleState.completed,
      ),
    );

    expect(find.text('Completed · Results are final'), findsOneWidget);
    for (final key in ['standings', 'matrix', 'sheet', 'cards']) {
      expect(_enabled(tester, key), isTrue, reason: key);
    }
  });

  testWidgets('Open launches the report and the card says so', (tester) async {
    final launcher = FakeReportLauncher();
    await _pump(
      tester,
      _server(matrix: drawnMatrix(), scored: _scored(2)),
      launcher: launcher,
    );

    await tester.ensureVisible(_open('cards'));
    await tester.tap(_open('cards'));
    await tester.pump();
    expect(launcher.opened, [
      contestReportPath(matrixContestId, ReportKind.cards),
    ]);
    expect(find.text('Opened in a new tab'), findsOneWidget);
    // Open stays enabled, with no spinner.
    expect(_enabled(tester, 'cards'), isTrue);

    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Opened in a new tab'), findsNothing);
  });

  testWidgets('a blocked tab offers Try again and Open here', (tester) async {
    final launcher = FakeReportLauncher(LaunchOutcome.blocked);
    await _pump(
      tester,
      _server(matrix: drawnMatrix(), scored: _scored(2)),
      launcher: launcher,
    );

    await tester.tap(_open('standings'));
    await tester.pump();
    expect(find.textContaining('blocked the new tab'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(launcher.opened, hasLength(2));

    await tester.tap(find.text('Open here'));
    await tester.pump();
    expect(launcher.openedHere, [
      contestReportPath(matrixContestId, ReportKind.standings),
    ]);
  });

  testWidgets('an in-place launch leaves the card quiet', (tester) async {
    final launcher = FakeReportLauncher(LaunchOutcome.inPlace);
    await _pump(
      tester,
      _server(matrix: drawnMatrix(), scored: _scored(2)),
      launcher: launcher,
    );
    await tester.tap(_open('standings'));
    await tester.pump();
    expect(find.text('Opened in a new tab'), findsNothing);
    expect(launcher.opened, hasLength(1));
  });

  testWidgets('the help popover defines the statuses', (tester) async {
    await _pump(tester, _server(matrix: drawnMatrix(), scored: _scored(2)));

    expect(find.byKey(const ValueKey('result-status-help')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('result-status-help-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('result-status-help')), findsOneWidget);
    expect(find.textContaining('stamped PRELIMINARY'), findsOneWidget);
  });

  group('states', () {
    testWidgets('loading shows a progress bar and a label', (tester) async {
      await _pump(
        tester,
        _server(matrix: drawnMatrix(), scored: _scored(2)),
        settle: false,
      );
      expect(find.byKey(const ValueKey('reports-loading')), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('a failed read offers Try again, and retrying recovers', (
      tester,
    ) async {
      final server = _server(matrix: drawnMatrix(), scored: _scored(2))
        ..networkDown = true;
      await _pump(tester, server);

      expect(find.text('Can’t read this contest’s data'), findsOneWidget);
      expect(find.byKey(const ValueKey('report-card-standings')), findsNothing);

      server.networkDown = false;
      await tester.tap(find.byKey(const ValueKey('reports-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('report-card-standings')), findsOne);
    });

    testWidgets('an unknown contest is not found', (tester) async {
      final server = _server(matrix: drawnMatrix(), scored: _scored(2))
        ..contestStatus = 404;
      final router = await _pump(tester, server);

      expect(find.text('Contest not found'), findsOneWidget);
      await tester.tap(find.text('Back to Contests'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, homePath);
    });

    testWidgets('an id that is not an id is not found', (tester) async {
      await _pump(tester, _server(), contestId: 'not-an-id');
      expect(find.text('Contest not found'), findsOneWidget);
    });
  });
}
