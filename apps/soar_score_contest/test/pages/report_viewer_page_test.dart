import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_contest/api_client_provider.dart';
import 'package:soar_score_contest/local_ui_store_provider.dart';
import 'package:soar_score_contest/pages/contest/report_viewer_page.dart';
import 'package:soar_score_contest/router.dart';
import 'package:soar_score_contest/services/matrix/matrix_page_data.dart';
import 'package:soar_score_contest/services/reports/draw_matrix/draw_matrix_data.dart';
import 'package:soar_score_contest/services/reports/draw_matrix/draw_matrix_options.dart';
import 'package:soar_score_contest/services/reports/report_kind.dart';
import 'package:soar_score_contest/services/reports/reports_facts.dart';
import 'package:soar_score_contest/services/reports/viewer/page_setup.dart';
import 'package:soar_score_contest/services/reports/viewer/report_options_store.dart';
import 'package:soar_score_contest/services/reports/viewer/report_print_result.dart';
import 'package:soar_score_contest/services/reports/viewer/report_spec.dart';
import 'package:soar_score_contest/services/reports/viewer/report_view_params.dart';
import 'package:soar_score_contest/widgets/reports/draw_matrix/draw_matrix_controls.dart';
import 'package:soar_score_contest/widgets/reports/viewer/report_definition.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import '../support/fake_report_launcher.dart';
import '../support/matrix_test_support.dart';
import '../support/next_step_widget_support.dart';
import '../support/stand_in_report.dart';
import '../support/workspace_facts_support.dart';

Map<(int, int), DateTime> _scored(int rounds) => {
  for (var r = 1; r <= rounds; r++)
    for (var p = 1; p <= 4; p++) (r, p): at(r * 10 + p),
};

WorkspaceServer _server({int scoredRounds = 2}) {
  final matrix = drawnMatrix();
  return WorkspaceServer(
    configuration: matrixConfiguration(),
    matrix: matrix,
    scores: scoresFor(matrix, _scored(scoredRounds)),
  );
}

Future<List<ReportViewParams>> _pump(
  WidgetTester tester,
  WorkspaceServer server, {
  Size size = const Size(1280, 1000),
  ReportViewParams params = const ReportViewParams(),
  FakeReportPrinter? printer,
  bool openedInPlace = false,
  Duration? pollInterval,
  String contestId = matrixContestId,
  ReportKind? report = ReportKind.standings,
  bool settle = true,
  Locale appLocale = const Locale('en', 'US'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final changes = <ReportViewParams>[];
  await tester.pumpWidget(
    ApiClientInherited(
      client: ApiClient(
        baseUrl: Uri.parse('http://localhost'),
        httpClient: MockClient(server.handle),
      ),
      child: MaterialApp(
        locale: appLocale,
        home: ReportViewerPage(
          contestId: contestId,
          report: report,
          params: params,
          openedInPlace: openedInPlace,
          definitionFor: (_) => const StandInReport(),
          printer: printer ?? FakeReportPrinter(ReportPrintResult.sent),
          launcher: FakeReportLauncher(),
          onParams: changes.add,
          pollInterval: pollInterval,
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
  return changes;
}

Finder _text(String text) => find.text(text);
Finder _body(int page, {String rounds = '1-2'}) =>
    find.text('Rounds $rounds body $page');

Future<void> _choose(WidgetTester tester, String field, String option) async {
  await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, field));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the report on paper pages with its identity', (
    tester,
  ) async {
    await _pump(tester, _server());

    expect(find.byKey(const ValueKey('viewer-title')).evaluate().length, 1);
    expect(_text('Overall Standings'), findsOneWidget);
    expect(find.byKey(const ValueKey('viewer-subtitle')), findsOneWidget);
    expect(_body(1), findsOneWidget);
    expect(_body(2), findsOneWidget);
    expect(
      find.text('Overall Results - ${_contestName(tester)}'),
      findsNWidgets(2),
    );
    // The running footer repeats on every page.
    expect(find.textContaining('Page 1 of 2'), findsWidgets);
    expect(find.textContaining('Page 2 of 2'), findsWidgets);
    expect(find.text('Page 1 of 2'), findsWidgets);
    expect(find.byKey(const ValueKey('viewer-page-indicator')), findsOneWidget);
  });

  testWidgets('marks a preliminary result on screen and on paper', (
    tester,
  ) async {
    await _pump(tester, _server());

    expect(find.textContaining('Preliminary:'), findsOneWidget);
    expect(
      find.textContaining('round 2 has 2 missing scores.'),
      findsOneWidget,
    );
    expect(find.text('PRELIMINARY'), findsNWidgets(4));
  });

  group('page setup', () {
    testWidgets('starts from the locale and the report, and says what prints', (
      tester,
    ) async {
      await _pump(tester, _server());
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('viewer-setup-text')))
            .data,
        'Letter · Landscape · 2 pages',
      );
    });

    testWidgets('a bare language locale takes its country from the system', (
      tester,
    ) async {
      tester.platformDispatcher.localeTestValue = const Locale('en', 'US');
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      await _pump(tester, _server(), appLocale: const Locale('en'));
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('viewer-setup-text')))
            .data,
        'Letter · Landscape · 2 pages',
      );
    });

    testWidgets('paper and orientation change the sheet and the URL', (
      tester,
    ) async {
      final changes = await _pump(tester, _server());

      await tester.tap(find.text('A4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portrait'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('viewer-setup-text')))
            .data,
        'A4 · Portrait · 2 pages',
      );
      expect(changes.last.toQuery(), {'paper': 'a4', 'orient': 'portrait'});
    });

    testWidgets('a URL restores filters, options and page setup', (
      tester,
    ) async {
      await _pump(
        tester,
        _server(),
        params: ReportViewParams.fromQuery(const {
          'f.to': '1',
          'f.pct': '1',
          'paper': 'a4',
          'orient': 'landscape',
        }),
      );
      expect(_body(1, rounds: '1-1'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('viewer-setup-text')))
            .data,
        'A4 · Landscape · 2 pages',
      );
      expect(
        tester
            .widget<Checkbox>(
              find.descendant(
                of: find.widgetWithText(
                  CheckboxListTile,
                  'Percentage of total',
                ),
                matching: find.byType(Checkbox),
              ),
            )
            .value,
        isTrue,
      );
    });
  });

  group('filters', () {
    testWidgets('a change updates the sheet at once and the URL', (
      tester,
    ) async {
      final changes = await _pump(tester, _server());
      await _choose(tester, 'To round', 'Round 1');

      expect(_body(1, rounds: '1-1'), findsOneWidget);
      expect(find.byType(FilledButton).evaluate().isNotEmpty, isTrue);
      expect(changes.last.filters, {'to': '1'});
    });

    testWidgets('an invalid range keeps the last good sheet and says why', (
      tester,
    ) async {
      await _pump(tester, _server());
      await _choose(tester, 'From round', 'Round 2');
      expect(_body(1, rounds: '2-2'), findsOneWidget);

      await _choose(tester, 'To round', 'Round 1');
      expect(
        find.text('From round must be on or before To round.'),
        findsOneWidget,
      );
      // The sheet stays on the last good result.
      expect(_body(1, rounds: '2-2'), findsOneWidget);
      expect(_body(1, rounds: '2-1'), findsNothing);
    });

    testWidgets('nothing to show offers Reset filters', (tester) async {
      await _pump(
        tester,
        _server(),
        params: ReportViewParams.fromQuery(const {'f.empty': '1'}),
      );
      expect(find.text('No scores in these rounds'), findsOneWidget);
      expect(_body(1), findsNothing);
      // Nothing to print.
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('viewer-print')))
            .onPressed,
        isNull,
      );

      await tester.tap(find.text('Reset filters'));
      await tester.pumpAndSettle();
      expect(_body(1), findsOneWidget);
    });
  });

  group('displayed versus printable', () {
    testWidgets(
      'page breaks and screen-only marks show, then print preview hides them',
      (tester) async {
        await _pump(tester, _server());
        expect(find.textContaining('Page break · Page 2'), findsOneWidget);
        expect(find.text('Screen only mark'), findsNWidgets(2));
        expect(
          find.textContaining('The white pages print exactly as shown'),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey('viewer-preview-switch')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Page break'), findsNothing);
        expect(find.text('Screen only mark'), findsNothing);
        expect(
          find.textContaining('Print preview: the white pages are exactly'),
          findsOneWidget,
        );
      },
    );

    testWidgets('the sheet stays black on white in a dark theme', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final server = _server();
      await tester.pumpWidget(
        ApiClientInherited(
          client: ApiClient(
            baseUrl: Uri.parse('http://localhost'),
            httpClient: MockClient(server.handle),
          ),
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: ReportViewerPage(
              printer: const NotWiredReportPrinter(),
              contestId: matrixContestId,
              report: ReportKind.standings,
              definitionFor: (_) => const StandInReport(),
              pollInterval: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final body = tester.widget<Text>(_body(1));
      final style = DefaultTextStyle.of(tester.element(_body(1))).style;
      expect(style.color, const Color(0xFF000000));
      expect(body.style?.color, anyOf(isNull, const Color(0xFF000000)));
    });
  });

  group('zoom', () {
    testWidgets('steps through fixed zooms and back to fit', (tester) async {
      final changes = await _pump(tester, _server());

      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
      expect(changes.last.zoom, isNotNull);

      // A fixed zoom toggles back to fit width, and fit toggles to 100%.
      await tester.tap(find.byKey(const ValueKey('viewer-zoom-toggle')));
      await tester.pumpAndSettle();
      expect(changes.last.zoom, isNull);

      await tester.tap(find.byKey(const ValueKey('viewer-zoom-toggle')));
      await tester.pumpAndSettle();
      expect(changes.last.zoom, 1);
    });
  });

  group('print', () {
    testWidgets('Print hands the sheet to the printer and says so', (
      tester,
    ) async {
      final printer = FakeReportPrinter(ReportPrintResult.sent);
      await _pump(tester, _server(), printer: printer);

      await tester.tap(find.byKey(const ValueKey('viewer-print')));
      await tester.pumpAndSettle();

      expect(printer.printed, hasLength(1));
      expect(printer.printed.single.pageCount, 2);
      expect(printer.printed.single.paperLabel, 'Letter');
      expect(printer.printed.single.pages, hasLength(2));
      expect(
        printer.printed.single.setup,
        const PageSetup(PaperSize.letter, PageOrientation.landscape),
      );
      expect(
        find.text('Sent to the printer · 2 pages, Letter, landscape.'),
        findsOneWidget,
      );
    });

    testWidgets('a second request while one runs is ignored', (tester) async {
      final printer = FakeReportPrinter(ReportPrintResult.sent);
      await _pump(tester, _server(), printer: printer);

      await tester.tap(find.byKey(const ValueKey('viewer-print')));
      // The first job is still preparing; Print is off and Ctrl+P does nothing.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(printer.printed, hasLength(1));
    });

    testWidgets('Ctrl+P prints too', (tester) async {
      final printer = FakeReportPrinter(ReportPrintResult.sent);
      await _pump(tester, _server(), printer: printer);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(printer.printed, hasLength(1));
    });

    testWidgets('cancelling is quiet and offers Print again', (tester) async {
      final printer = FakeReportPrinter(ReportPrintResult.cancelled);
      await _pump(tester, _server(), printer: printer);

      await tester.tap(find.byKey(const ValueKey('viewer-print')));
      await tester.pumpAndSettle();
      expect(find.text('Print cancelled. Nothing changed.'), findsOneWidget);

      await tester.tap(find.text('Print again'));
      await tester.pumpAndSettle();
      expect(printer.printed, hasLength(2));
    });

    testWidgets('the cancelled message goes away by itself', (tester) async {
      final printer = FakeReportPrinter(ReportPrintResult.cancelled);
      await _pump(tester, _server(), printer: printer);

      await tester.tap(find.byKey(const ValueKey('viewer-print')));
      await tester.pumpAndSettle();
      expect(find.text('Print cancelled. Nothing changed.'), findsOneWidget);

      await tester.pump(const Duration(seconds: 9));
      await tester.pumpAndSettle();
      expect(find.text('Print cancelled. Nothing changed.'), findsNothing);
    });

    testWidgets('a cancelled save offers Save again, not Print again', (
      tester,
    ) async {
      final printer = FakeReportPrinter(ReportPrintResult.cancelled);
      await _pump(tester, _server(), printer: printer);

      await tester.tap(find.byKey(const ValueKey('viewer-pdf')));
      await tester.pumpAndSettle();
      expect(find.text('Save cancelled. Nothing changed.'), findsOneWidget);

      await tester.tap(find.text('Save again'));
      await tester.pumpAndSettle();
      expect(printer.saved, hasLength(2));
      expect(printer.printed, isEmpty);
    });

    testWidgets('a failure keeps the filters and offers Try again or PDF', (
      tester,
    ) async {
      final printer = FakeReportPrinter(ReportPrintResult.failed);
      await _pump(tester, _server(), printer: printer);

      await tester.tap(find.byKey(const ValueKey('viewer-print')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Couldn’t print.'), findsOneWidget);
      expect(
        find.textContaining('filters and options are unchanged'),
        findsOneWidget,
      );

      printer.result = ReportPrintResult.sent;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Couldn’t print.'), findsNothing);
      expect(printer.printed, hasLength(2));
    });

    testWidgets('Save as PDF is a regular action beside Print', (tester) async {
      final printer = FakeReportPrinter(ReportPrintResult.sent);
      await _pump(tester, _server(), printer: printer);

      await tester.tap(find.byKey(const ValueKey('viewer-pdf')));
      await tester.pumpAndSettle();
      expect(printer.saved, hasLength(1));
      expect(find.textContaining('PDF saved'), findsOneWidget);
    });

    testWidgets('printing not built yet says so', (tester) async {
      final printer = FakeReportPrinter(ReportPrintResult.notWired);
      await _pump(tester, _server(), printer: printer);
      await tester.tap(find.byKey(const ValueKey('viewer-print')));
      await tester.pumpAndSettle();
      expect(find.text('Printing isn’t wired up yet.'), findsOneWidget);
    });

    testWidgets('where printing is unavailable Save as PDF is the primary', (
      tester,
    ) async {
      final printer = FakeReportPrinter(
        ReportPrintResult.sent,
        capabilities: const ReportPrintCapabilities(canPrint: false),
      );
      await _pump(tester, _server(), printer: printer);

      expect(
        find.textContaining('Printing isn’t available here.'),
        findsOneWidget,
      );
      expect(find.text('Printing unavailable'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('viewer-print')))
            .onPressed,
        isNull,
      );
      expect(find.byKey(const ValueKey('viewer-pdf')), findsOneWidget);
      expect(
        tester
            .widget<ButtonStyleButton>(find.byKey(const ValueKey('viewer-pdf')))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('with neither print nor PDF it explains and offers Copy link', (
      tester,
    ) async {
      final printer = FakeReportPrinter(
        ReportPrintResult.sent,
        capabilities: const ReportPrintCapabilities(
          canPrint: false,
          canSavePdf: false,
        ),
      );
      await _pump(
        tester,
        _server(),
        params: ReportViewParams.fromQuery(const {'f.pct': '1', 'preview': '1'}),
        openedInPlace: true,
        printer: printer,
      );
      expect(
        find.textContaining('This browser can’t print or save PDFs.'),
        findsOneWidget,
      );
      expect(find.text('Copy link'), findsOneWidget);

      // Capture the text handed to the system clipboard.
      final messenger = tester.binding.defaultBinaryMessenger;
      Object? copied;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map<String, dynamic>)['text'];
        }
        return null;
      });
      await tester.tap(find.text('Copy link'));
      await tester.pump();
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);

      // The link is the report's route with the view in force.
      final link = Uri.parse('$copied');
      expect(
        link.path,
        contestReportPath(matrixContestId, ReportKind.standings),
      );
      expect(link.queryParameters, {'f.pct': '1', 'preview': '1', 'back': '1'});
    });
  });

  group('states', () {
    testWidgets('loading shows a skeleton', (tester) async {
      await _pump(tester, _server(), settle: false);
      expect(find.byKey(const ValueKey('viewer-loading')), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('the loading skeleton scales down in a short window', (
      tester,
    ) async {
      await _pump(
        tester,
        _server(),
        size: const Size(1280, 450),
        settle: false,
      );
      expect(find.byKey(const ValueKey('viewer-loading')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });

    testWidgets('unreadable data offers Try again and keeps the page', (
      tester,
    ) async {
      final server = _server()..networkDown = true;
      await _pump(tester, server);
      expect(find.text('Can’t read the contest data'), findsOneWidget);

      server.networkDown = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(_body(1), findsOneWidget);
    });

    testWidgets('a contest that is gone says so', (tester) async {
      final server = _server()..contestStatus = 404;
      await _pump(tester, server);
      expect(find.text('This contest can’t be found'), findsOneWidget);
      expect(find.text('Back to Contests'), findsOneWidget);
    });

    testWidgets('an unknown report says so', (tester) async {
      await _pump(tester, _server(), report: null);
      expect(find.text('This report doesn’t exist'), findsOneWidget);
    });

    testWidgets('an out-of-date sheet offers Refresh and never redraws alone', (
      tester,
    ) async {
      final server = _server(scoredRounds: 1);
      await _pump(tester, server, pollInterval: const Duration(seconds: 1));
      expect(find.textContaining('Out of date.'), findsNothing);

      // Scores change in the contest.
      final matrix = drawnMatrix();
      server.scores = scoresFor(matrix, _scored(2));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(find.textContaining('Out of date.'), findsOneWidget);
      expect(find.textContaining('The sheet hasn’t changed.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('viewer-refresh')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Out of date.'), findsNothing);
    });
  });

  testWidgets(
    'a corrected score with the same counts marks the sheet out of date',
    (tester) async {
      final server = _server();
      await _pump(tester, server, pollInterval: const Duration(seconds: 1));

      // One score is corrected: every slot stays scored, only its time changes.
      final matrix = drawnMatrix();
      server.scores = scoresFor(matrix, {..._scored(2), (1, 2): at(500)});
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(find.textContaining('Out of date.'), findsOneWidget);
    },
  );

  group('window class', () {
    testWidgets('medium collapses the panel into a bar above the sheet', (
      tester,
    ) async {
      await _pump(tester, _server(), size: const Size(700, 1000));
      expect(find.byKey(const ValueKey('viewer-panel')), findsNothing);
      expect(find.text('Rounds 1–2 · Letter, landscape'), findsOneWidget);
      expect(find.text('From round'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('viewer-panel-toggle')));
      await tester.pumpAndSettle();
      expect(find.text('From round'), findsOneWidget);
      expect(find.text('Percentage of total'), findsOneWidget);
    });

    testWidgets('compact moves the panel into a bottom sheet', (tester) async {
      await _pump(tester, _server(), size: const Size(400, 900));
      expect(find.text('From round'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('viewer-filters-button')));
      await tester.pumpAndSettle();
      expect(find.text('Filter and options'), findsOneWidget);
      expect(find.text('From round'), findsOneWidget);

      await _choose(tester, 'To round', 'Round 1');
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(_body(1, rounds: '1-1'), findsOneWidget);
    });
  });

  testWidgets('opened in place, the leading button goes back to Reports', (
    tester,
  ) async {
    await _pump(tester, _server(), openedInPlace: true);
    expect(find.byKey(const ValueKey('viewer-back')), findsOneWidget);
  });

  testWidgets('the header is opaque and does not tint when scrolled', (
    tester,
  ) async {
    await _pump(tester, _server());
    final bar = tester.widget<AppBar>(find.byType(AppBar));
    expect(bar.backgroundColor?.a, 1.0);
    expect(bar.surfaceTintColor, Colors.transparent);
    expect(bar.scrolledUnderElevation, 0);
  });

  testWidgets('a web tab has no leading button', (tester) async {
    await _pump(tester, _server());
    expect(find.byKey(const ValueKey('viewer-back')), findsNothing);
  });

  test('paper defaults by locale', () {
    expect(PaperSize.forLocale(const Locale('en', 'US')), PaperSize.letter);
    expect(PaperSize.forLocale(const Locale('en', 'GB')), PaperSize.a4);
    expect(PaperSize.forLocale(const Locale('de')), PaperSize.a4);
    expect(PaperSize.forLocale(const Locale('en')), PaperSize.a4);
    expect(
      PaperSize.forLocale(const Locale('en'), system: const Locale('en', 'US')),
      PaperSize.letter,
    );
    expect(
      PaperSize.forLocale(
        const Locale('en', 'GB'),
        system: const Locale('en', 'US'),
      ),
      PaperSize.a4,
    );
    expect(PageSetup(PaperSize.letter, PageOrientation.landscape).width, 1056);
  });

  group('remembered options', () {
    Future<LocalUiStore> pumpWithStore(
      WidgetTester tester,
      LocalUiStore uiStore,
      ReportDefinition definition, {
      ReportKind report = ReportKind.standings,
      ReportViewParams params = const ReportViewParams(),
    }) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final server = _server();
      await tester.pumpWidget(
        LocalUiStoreInherited(
          store: uiStore,
          child: ApiClientInherited(
            client: ApiClient(
              baseUrl: Uri.parse('http://localhost'),
              httpClient: MockClient(server.handle),
            ),
            child: MaterialApp(
              locale: const Locale('en', 'US'),
              home: ReportViewerPage(
                contestId: matrixContestId,
                report: report,
                params: params,
                definitionFor: (_) => definition,
                printer: FakeReportPrinter(ReportPrintResult.sent),
                launcher: FakeReportLauncher(),
                pollInterval: null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return uiStore;
    }

    testWidgets('a stored option shows in the panel and is written on change', (
      tester,
    ) async {
      final uiStore = BackendLocalUiStore(MemoryLocalUiBackend());
      await ReportOptionsStore(uiStore, 'local')
          .set('standings', {'pct': '1'});
      await pumpWithStore(tester, uiStore, const StandInReport());

      // The stored '1' is on before anything is touched.
      expect(_option(tester, 'Percentage of total'), isTrue);
      final store = ReportOptionsStore(uiStore, 'local');

      // Changing it writes the new value, even back to the default.
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Percentage of total'));
      await tester.pumpAndSettle();
      expect(await store.load(), {'standings': {'pct': '0'}});
      expect(_option(tester, 'Percentage of total'), isFalse);
    });

    testWidgets('a value the URL names does not reach the store', (tester) async {
      final uiStore = BackendLocalUiStore(MemoryLocalUiBackend());
      await pumpWithStore(
        tester,
        uiStore,
        const StandInReport(),
        params: ReportViewParams.fromQuery(const {'f.pct': '1'}),
      );
      expect(
        await ReportOptionsStore(uiStore, 'local').load(),
        isEmpty,
      );
    });

    testWidgets('reopening the report starts with the stored choice', (
      tester,
    ) async {
      final uiStore = BackendLocalUiStore(MemoryLocalUiBackend());
      await pumpWithStore(tester, uiStore, const StandInReport());
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Percentage of total'));
      await tester.pumpAndSettle();

      // A fresh widget on the same store starts with the stored value on.
      await tester.pumpWidget(const SizedBox());
      await pumpWithStore(tester, uiStore, const StandInReport());
      expect(_option(tester, 'Percentage of total'), isTrue);
    });

    testWidgets('the overflow menu reset clears the stored options', (
      tester,
    ) async {
      final uiStore = BackendLocalUiStore(MemoryLocalUiBackend());
      await ReportOptionsStore(uiStore, 'local')
          .set('standings', {'pct': '1', 'paper': 'a4'});
      await pumpWithStore(tester, uiStore, const StandInReport());
      expect(_option(tester, 'Percentage of total'), isTrue);

      await tester.tap(find.byKey(const ValueKey('viewer-overflow')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset filters and options'));
      await tester.pumpAndSettle();

      expect(_option(tester, 'Percentage of total'), isFalse);
      expect(
        await ReportOptionsStore(uiStore, 'local').load(),
        isEmpty,
      );
    });

    testWidgets('the empty-state reset keeps the stored options', (
      tester,
    ) async {
      final uiStore = BackendLocalUiStore(MemoryLocalUiBackend());
      await ReportOptionsStore(uiStore, 'local')
          .set('standings', {'pct': '1'});
      await pumpWithStore(
        tester,
        uiStore,
        const StandInReport(),
        params: ReportViewParams.fromQuery(const {'f.empty': '1'}),
      );
      expect(find.text('No scores in these rounds'), findsOneWidget);

      await tester.tap(find.text('Reset filters'));
      await tester.pumpAndSettle();
      expect(_body(1), findsOneWidget);
      expect(_option(tester, 'Percentage of total'), isTrue);
      expect(
        await ReportOptionsStore(uiStore, 'local').load(),
        {'standings': {'pct': '1'}},
      );
    });

    testWidgets('the Draw Matrix remembers Compact mode per report kind', (
      tester,
    ) async {
      final uiStore = BackendLocalUiStore(MemoryLocalUiBackend());
      await pumpWithStore(
        tester,
        uiStore,
        const _MatrixDefinition(),
        report: ReportKind.matrix,
      );
      final compact = find.widgetWithText(SwitchListTile, 'Compact mode');
      expect(tester.widget<SwitchListTile>(compact).value, isFalse);
      final store = ReportOptionsStore(uiStore, 'local');

      await tester.tap(compact);
      await tester.pumpAndSettle();
      // The stored entry is keyed to the matrix kind, not to standings.
      expect(await store.load(), {'matrix': {'cmp': '1'}});

      // Reopening starts with it on.
      await tester.pumpWidget(const SizedBox());
      await pumpWithStore(
        tester,
        uiStore,
        const _MatrixDefinition(),
        report: ReportKind.matrix,
      );
      expect(tester.widget<SwitchListTile>(compact).value, isTrue);
    });
  });
}

/// The real Draw Matrix report's controls and data read, so its Compact mode
/// control is in the panel. The data is read through the page's own client.
class _MatrixDefinition extends ReportDefinition {
  const _MatrixDefinition();

  @override
  ReportKind get kind => ReportKind.matrix;

  @override
  Map<String, String> defaultFilters(ReportsFacts facts) =>
      DrawMatrixOptions.defaults(facts);

  @override
  ReportCheck check(Map<String, String> filters, ReportsFacts facts) =>
      DrawMatrixOptions.of(filters, facts).check();

  @override
  String filterSummary(Map<String, String> filters, ReportsFacts facts) =>
      DrawMatrixOptions.of(filters, facts).summary;

  @override
  String? dataKey(Map<String, String> filters, ReportsFacts facts) =>
      'matrix=${facts.matrixRevision}';

  @override
  Future<ReportLoad<Object>> loadData(ReportDataRequest request) async {
    final page = await MatrixPageData.forContest(
      request.client,
      request.facts.contest,
    );
    return ReportLoaded(DrawMatrixData.of(page));
  }

  @override
  List<ReportControlGroup> controls(ReportControlsContext context) =>
      drawMatrixControls(
        context,
        DrawMatrixOptions.of(context.filters, context.facts),
      );

  @override
  ReportDocument build(ReportPageContext context) => ReportDocument(
    title: 'Flight Matrix - ${context.facts.contest.name}',
    subtitle: 'No matrix to show',
    pages: const [SizedBox.shrink()],
  );
}

/// The value of the checkbox with [label] in the options panel.
bool _option(WidgetTester tester, String label) => tester
    .widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, label))
    .value!;

String _contestName(WidgetTester tester) => matrixContest().name;
