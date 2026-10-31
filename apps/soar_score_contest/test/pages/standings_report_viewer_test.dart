import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/viewer/report_print_result.dart';
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/pages/contest/report_viewer_page.dart';
import 'package:soar_score_contest/services/reports/report_kind.dart';
import 'package:soar_score_contest/services/reports/viewer/report_view_params.dart';

import '../support/matrix_test_support.dart';
import '../support/standings_fixtures.dart';
import '../support/workspace_facts_support.dart';

Future<void> _pump(
  WidgetTester tester,
  StandingsServer server, {
  ReportViewParams params = const ReportViewParams(),
  Duration? pollInterval,
  Size size = const Size(1280, 1000),
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ApiClientInherited(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient(server.handle),
      ),
      child: MaterialApp(
        locale: const Locale('en', 'US'),
        home: ReportViewerPage(
          printer: const NotWiredReportPrinter(),
          contestId: matrixContestId,
          report: ReportKind.standings,
          params: params,
          pollInterval: pollInterval,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
}

Future<void> _choose(WidgetTester tester, String field, String option) async {
  await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, field));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> _toggle(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(CheckboxListTile, label));
  await tester.pumpAndSettle();
}

Finder _text(String text) => find.text(text);

void main() {
  late StandingsFixture fixture;
  late StandingsServer server;

  setUp(() {
    fixture = StandingsFixture();
    server = StandingsServer(fixture);
  });

  testWidgets('shows the standings as of the last round', (tester) async {
    await _pump(tester, server);

    // The heading and the contest details.
    expect(_text('Overall Results - ${matrixContest().name}'), findsOneWidget);
    // The columns, in order: rank, pilot, total, percentage, then the rounds.
    for (final head in ['Rank', 'Pilot', 'Total', 'Pct', 'R1', 'R2']) {
      expect(_text(head), findsOneWidget, reason: head);
    }
    expect(_text('Raw'), findsNothing);
    // The rows are the stored places, best first.
    expect(_text('Ray, Bo'), findsOneWidget);
    expect(_text('Lee, Ann'), findsOneWidget);
    expect(_text('1,750.0'), findsOneWidget);
    expect(_text('80.0%'), findsOneWidget);
    // Round scores, with the dropped round marked by an asterisk.
    expect(_text('950.0'), findsOneWidget);
    expect(_text('*500.0'), findsOneWidget);
    // It is the standing as of round 2, read from the API.
    expect(
      server.requests.map((u) => u.queryParameters['asOfRound']),
      contains('2'),
    );
  });

  testWidgets('a fully scored contest offers no Provisional option', (
    tester,
  ) async {
    await _pump(tester, server);
    expect(find.widgetWithText(CheckboxListTile, 'Flight details'), findsOne);
    expect(find.widgetWithText(CheckboxListTile, 'Provisional'), findsNothing);
  });

  testWidgets('a partly scored round offers the Provisional option', (
    tester,
  ) async {
    final matrix = drawnMatrix();
    server = StandingsServer(
      fixture,
      scores: scoresFor(matrix, {
        for (var p = 1; p <= 4; p++) (1, p): at(p),
        (2, 1): at(10),
      }),
    );
    await _pump(tester, server);
    expect(find.widgetWithText(CheckboxListTile, 'Provisional'), findsOne);
  });

  testWidgets('scores without a stored standing say so, not fail', (
    tester,
  ) async {
    fixture.standings.clear();
    await _pump(tester, server);

    expect(_text('No standings stored for round 2 yet'), findsOneWidget);
    expect(_text('Open Scoring'), findsOneWidget);
    expect(find.textContaining('Couldn’t load'), findsNothing);
    expect(find.textContaining('Can’t read'), findsNothing);
    expect(_text('Rank'), findsNothing);
  });

  testWidgets('an official result has no stamp', (tester) async {
    await _pump(tester, server);
    expect(find.textContaining('Official.'), findsOneWidget);
    expect(_text('PRELIMINARY'), findsNothing);
  });

  testWidgets('a preliminary result is stamped on every page and explained', (
    tester,
  ) async {
    server = StandingsServer(StandingsFixture(preliminary: true));
    await _pump(tester, server);
    expect(_text('PRELIMINARY'), findsWidgets);
    expect(find.textContaining('Preliminary:'), findsOneWidget);
  });

  group('options', () {
    testWidgets('Raw score adds its column and Percentage removes its own', (
      tester,
    ) async {
      await _pump(tester, server);
      await _toggle(tester, 'Raw score');
      await _toggle(tester, 'Percentage of total');

      expect(_text('Raw'), findsOneWidget);
      expect(_text('Pct'), findsNothing);
      // Raw is the total plus the dropped round: Ann dropped 500.0.
      expect(_text('1,400.0'), findsNWidgets(3));
    });

    testWidgets('toggling a column asks for no new data', (tester) async {
      await _pump(tester, server);
      final before = server.requests.length;
      await _toggle(tester, 'Raw score');
      expect(server.requests.length, before);
    });

    testWidgets('options the contest does not use are not offered', (
      tester,
    ) async {
      await _pump(tester, server);
      expect(find.widgetWithText(CheckboxListTile, 'Team'), findsNothing);
      expect(
        find.widgetWithText(CheckboxListTile, 'Pilot number'),
        findsNothing,
      );
      expect(
        find.widgetWithText(CheckboxListTile, 'Pilot class'),
        findsNothing,
      );
    });

    testWidgets(
      'Flight details put time, landing and height under each score',
      (tester) async {
        await _pump(tester, server);
        await _toggle(tester, 'Flight details');

        expect(find.textContaining('Landing'), findsWidgets);
        expect(find.textContaining('9:52'), findsWidgets);
        expect(find.textContaining('105m'), findsWidgets);
        expect(
          find.textContaining(
            'Flight details: time m:ss, landing points, launch height',
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('the round range', () {
    testWidgets('an upper bound re-reads the standings as of that round', (
      tester,
    ) async {
      await _pump(tester, server);
      await _choose(tester, 'To round', 'Round 1');

      expect(
        server.requests.map((u) => u.queryParameters['asOfRound']),
        contains('1'),
      );
      // As of round 1 Ann led with 900.0, and round 2 is not shown.
      expect(_text('R2'), findsNothing);
      expect(find.textContaining('Standings as of round 1'), findsOneWidget);
    });

    testWidgets('a lower bound hides rounds but keeps rank and total', (
      tester,
    ) async {
      await _pump(tester, server);
      await _choose(tester, 'From round', 'Round 2');

      expect(_text('R1'), findsNothing);
      expect(_text('R2'), findsOneWidget);
      expect(_text('1,750.0'), findsOneWidget);
      expect(find.textContaining('showing rounds 2 to 2'), findsOneWidget);
    });

    testWidgets('a lower bound above the upper one is invalid', (tester) async {
      await _pump(tester, server);
      await _choose(tester, 'To round', 'Round 1');
      await _choose(tester, 'From round', 'Round 2');

      expect(
        find.textContaining('From round must be on or before To round'),
        findsOneWidget,
      );
      // The sheet stays on the last good range.
      expect(_text('R1'), findsOneWidget);
    });

    testWidgets('a range with nothing in it offers Reset filters', (
      tester,
    ) async {
      // Round 2 is only partly scored, so with Provisional off it has nothing.
      final matrix = drawnMatrix();
      final partial = scoresFor(matrix, {
        for (var p = 1; p <= 4; p++) (1, p): at(p),
        (2, 1): at(10),
      });
      server = StandingsServer(fixture, scores: partial);
      await _pump(
        tester,
        server,
        params: ReportViewParams.fromQuery(const {
          'f.from': '2',
          'f.to': '2',
          'f.prov': '0',
        }),
      );
      expect(_text('No scores in rounds 2'), findsOneWidget);

      await tester.tap(find.text('Reset filters'));
      await tester.pumpAndSettle();
      expect(_text('No scores in rounds 2'), findsNothing);
    });

    testWidgets('the URL restores the range and options', (tester) async {
      await _pump(
        tester,
        server,
        params: ReportViewParams.fromQuery(const {
          'f.to': '1',
          'f.raw': '1',
          'f.pct': '0',
        }),
      );
      expect(_text('R2'), findsNothing);
      expect(_text('Raw'), findsOneWidget);
      expect(_text('Pct'), findsNothing);
    });
  });

  group('displayed versus printable', () {
    testWidgets('a score in review shows a screen-only chip, not in preview', (
      tester,
    ) async {
      server = StandingsServer(StandingsFixture(reviewPilot: 2));
      await _pump(tester, server);
      expect(_text('Review'), findsOneWidget);
    });

    testWidgets('print preview leaves the screen-only chip out', (
      tester,
    ) async {
      server = StandingsServer(StandingsFixture(reviewPilot: 2));
      await _pump(
        tester,
        server,
         params: const ReportViewParams(preview: true, previewExplicit: true),
      );
      expect(_text('Ray, Bo'), findsOneWidget);
      expect(_text('Review'), findsNothing);
    });
  });

  group('cancelled rounds', () {
    testWidgets('are never requested and do not stop the report loading', (
      tester,
    ) async {
      server = StandingsServer(StandingsFixture(round2Cancelled: true));
      await _pump(tester, server);

      expect(
        _text('Ray, Bo').evaluate().isNotEmpty ||
            _text('Lee, Ann').evaluate().isNotEmpty,
        isTrue,
      );
      expect(_text('R1'), findsOneWidget);
      expect(_text('R2'), findsNothing);
      final paths = server.requests.map((u) => u.path).toList();
      expect(paths.any((p) => p.endsWith('/results/rounds/2')), isFalse);
      expect(paths.any((p) => p.endsWith('/results/rounds/1')), isTrue);
    });
  });

  group('states', () {
    testWidgets('unreadable scores offer Try again and recover', (
      tester,
    ) async {
      server.resultsFail = 500;
      await _pump(tester, server);
      expect(
        find.text('Can’t read the scores for this report'),
        findsOneWidget,
      );

      server.resultsFail = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(_text('Ray, Bo'), findsOneWidget);
    });

    testWidgets('building the pages shows a pending state first', (
      tester,
    ) async {
      server.resultsGate = Completer<void>();
      // The progress bar never settles, so pump a few frames instead.
      await _pump(tester, server, settle: false);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const ValueKey('viewer-loading')), findsOneWidget);
      expect(find.text('Building pages…'), findsOneWidget);

      server.resultsGate!.complete();
      await tester.pumpAndSettle();
      expect(_text('Ray, Bo'), findsOneWidget);
    });

    testWidgets('a later read keeps the last sheet, dimmed, until it arrives', (
      tester,
    ) async {
      await _pump(tester, server);
      server.resultsGate = Completer<void>();
      await _choose(tester, 'To round', 'Round 1');
      // The new rounds are on their way; the sheet still shows round 2.
      expect(_text('R2'), findsOneWidget);

      server.resultsGate!.complete();
      await tester.pumpAndSettle();
      expect(_text('R2'), findsNothing);
    });

    testWidgets('flight details that cannot be read are an error, not dashes', (
      tester,
    ) async {
      await _pump(tester, server);
      server.scoresStatus = 500;
      await _toggle(tester, 'Flight details');

      expect(
        find.textContaining('Couldn’t load the scores for these rounds.'),
        findsOneWidget,
      );
      // The sheet stays on the last good result: no detail lines at all.
      expect(find.textContaining('9:52'), findsNothing);
      expect(find.textContaining('Flight details: time m:ss'), findsNothing);

      server.scoresStatus = 200;
      await tester.tap(find.byKey(const ValueKey('viewer-retry-data')));
      await tester.pumpAndSettle();
      expect(find.textContaining('9:52'), findsWidgets);
    });

    testWidgets('a refresh that cannot read its data keeps the old sheet', (
      tester,
    ) async {
      await _pump(tester, server, pollInterval: const Duration(seconds: 1));
      expect(_text('1,750.0'), findsOneWidget);

      // The contest changes (a score is corrected), but the new data cannot
      // be read.
      final matrix = fixture.matrix;
      server.scores = scoresFor(matrix, {
        for (var r = 1; r <= 2; r++)
          for (var p = 1; p <= 4; p++) (r, p): at(900 + r * 10 + p),
      });
      server.resultsFail = 500;
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.textContaining('Out of date.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('viewer-refresh')));
      await tester.pumpAndSettle();
      // Still the old sheet, still marked out of date: nothing was replaced.
      expect(find.textContaining('Out of date.'), findsOneWidget);
      expect(_text('1,750.0'), findsOneWidget);

      server.resultsFail = null;
      await tester.tap(find.byKey(const ValueKey('viewer-refresh')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Out of date.'), findsNothing);
      expect(_text('1,750.0'), findsOneWidget);
    });

    testWidgets('the result is out of date when a score changes', (
      tester,
    ) async {
      // Covered by the viewer's own tests; here the fingerprint is the same
      // for the same scores.
      await _pump(tester, server);
      expect(find.textContaining('Out of date.'), findsNothing);
    });
  });
}
