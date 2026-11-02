import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:soar_score_contest/services/reports/viewer/page_setup.dart';
import 'package:soar_score_contest/services/reports/viewer/report_options_store.dart';
import 'package:soar_score_contest/services/reports/viewer/report_print_result.dart';
import 'package:soar_score_contest/services/reports/viewer/report_spec.dart';
import 'package:soar_score_contest/services/reports/viewer/report_view_params.dart';
import 'package:soar_score_contest/services/reports/viewer/report_viewer_controller.dart';
import 'package:soar_score_ui_storage/soar_score_ui_storage.dart';

import '../../../support/matrix_test_support.dart';
import '../../../support/next_step_widget_support.dart';
import '../../../support/stand_in_report.dart';
import '../../../support/workspace_facts_support.dart';

const _account = 'local';

final DateTime _t0 = DateTime.utc(2026, 10, 17, 14);

Map<(int, int), DateTime> _scored(int rounds) => {
  for (var r = 1; r <= rounds; r++)
    for (var p = 1; p <= 4; p++) (r, p): _t0.add(Duration(minutes: r * 10 + p)),
};

/// The stand-in report against the fixture server; [stored] is what the
/// account already remembers.
Future<ReportViewerController> _controller({
  Map<String, Map<String, String>> stored = const {},
  ReportViewParams initial = const ReportViewParams(),
  LocalUiStore? uiStore,
}) async {
  final store = uiStore ?? BackendLocalUiStore(MemoryLocalUiBackend());
  for (final entry in stored.entries) {
    await ReportOptionsStore(store, _account).set(entry.key, entry.value);
  }
  final matrix = drawnMatrix();
  final server = WorkspaceServer(
    configuration: matrixConfiguration(),
    matrix: matrix,
    scores: scoresFor(matrix, _scored(2)),
  );
  final controller = ReportViewerController(
    client: ApiClient(
      baseUrl: Uri.parse('http://localhost'),
      httpClient: MockClient(server.handle),
    ),
    contestId: Id.parse(matrixContestId),
    spec: const StandInReport(),
    defaultPaper: PaperSize.letter,
    printer: FakeReportPrinter(ReportPrintResult.sent),
    initial: initial,
    pollInterval: null,
    options: ReportOptionsStore(store, _account),
  );
  await controller.start();
  addTearDown(controller.dispose);
  return controller;
}

/// The memory backend settles in a turn; let the unawaited write land.
Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('a settings reset applies the next time a report opens', () async {
    final uiStore = BackendLocalUiStore(MemoryLocalUiBackend());
    // A remembered option, then the Settings page reset that removes it.
    final seeded = ReportOptionsStore(uiStore, _account);
    await seeded.set('standings', {'pct': '1'});
    await ReportOptionsStore(uiStore, _account).reset();

    // A freshly opened report re-reads the store and starts from defaults.
    final controller = await _controller(uiStore: uiStore);
    expect(controller.filters['pct'], isNull);
  });

  test('a stored option applies over the default', () async {
    final controller = await _controller(
      stored: {
        'standings': {'pct': '1'},
      },
    );
    expect(controller.load, ViewerLoad.ready);
    // The stand-in's default is off; the stored '1' turns it on.
    expect(controller.filters['pct'], '1');
  });

  test('a stored value the viewer no longer recognises is dropped', () async {
    final controller = await _controller(
      stored: {
        'standings': {'pct': 'bogus', 'raw': '1', 'paper': 'not-a-paper'},
      },
    );
    // The unrecognised boolean and the bogus paper are forgotten at load.
    expect(controller.filters['pct'], isNull);
    expect(controller.params.paper, isNull);
    // The recognised value stays and applies over the default.
    expect(controller.filters['raw'], '1');
    // The recognised paper stays: the view starts from it.
    final controller2 = await _controller(
      stored: {
        'standings': {'paper': 'a4'},
      },
    );
    expect(controller2.params.paper, PaperSize.a4);
  });

  test('a URL option beats the stored one', () async {
    final controller = await _controller(
      stored: {
        'standings': {'pct': '1'},
      },
      initial: ReportViewParams.fromQuery(const {'f.pct': '0'}),
    );
    expect(controller.filters['pct'], '0');
  });

  test(
    'a value the URL names and the user did not touch is not written',
    () async {
      final controller = await _controller(
        initial: ReportViewParams.fromQuery(const {'f.pct': '1'}),
      );
      expect(controller.filters['pct'], '1');
      // The option came from the URL, not a change in the viewer.
      final store = _storeOf(controller);
      expect(await store.load('standings'), isEmpty);
    },
  );

  test('changing an option writes the account map', () async {
    final controller = await _controller();
    final store = _storeOf(controller);
    expect(await store.load('standings'), isEmpty);

    controller.setFilter('pct', '0');
    await _flush();
    // '0' is the default, but it is the user's last explicit choice.
    expect(await store.load('standings'), {'pct': '0'});

    controller.setFilter('pct', '1');
    await _flush();
    expect(await store.load('standings'), {'pct': '1'});
  });

  test('a round filter is not remembered', () async {
    final controller = await _controller();
    final store = _storeOf(controller);
    controller.setFilter('from', '2');
    await _flush();
    expect(await store.load('standings'), isEmpty);
  });

  test('prov is never remembered, only kept in the view', () async {
    final controller = await _controller();
    final store = _storeOf(controller);
    controller.setFilter('prov', '0');
    await _flush();
    // The choice reaches the view but never the account map.
    expect(controller.filters['prov'], '0');
    expect(await store.load('standings'), isEmpty);
  });

  test(
    'paper and preview are remembered, the pages to print are not',
    () async {
      final controller = await _controller();
      final store = _storeOf(controller);

      controller.setPaper(PaperSize.a4);
      controller.setPreview(true);
      controller.setPrintPages('1-2');
      await _flush();
      // The pages to print stay out of the account map.
      expect(await store.load('standings'), {'paper': 'a4', 'preview': '1'});
      expect(controller.params.previewExplicit, isTrue);
      // The range the user typed is in this view's params and URL only.
      expect(controller.params.printPages, '1-2');
      expect(controller.params.printPagesExplicit, isTrue);
      expect(controller.params.toQuery()['pp'], '1-2');
    },
  );

  test(
    'a stored preview applies, a stored pages-to-print is ignored',
    () async {
      final controller = await _controller(
        stored: {
          'standings': {'preview': '1', 'pp': '2'},
        },
      );
      expect(controller.preview, isTrue);
      // The stale stored range does not carry over: the view starts on all
      // pages and the URL names no range.
      expect(controller.printPages, isEmpty);
      expect(controller.params.toQuery(), {'preview': '1'});

      controller.setPreview(false);
      await _flush();
      expect(controller.preview, isFalse);
      expect(controller.params.toQuery(), {'preview': '0'});
    },
  );

  test(
    'the viewer reset clears the view state and removes the kind entry',
    () async {
      final controller = await _controller(
        stored: {
          'standings': {'pct': '1', 'paper': 'a4'},
          'matrix': {'cmp': '1'},
        },
        initial: ReportViewParams.fromQuery(const {
          'f.pct': '0',
          'paper': 'letter',
          'preview': '1',
          'pp': '2',
          'zoom': '1.25',
        }),
      );
      expect(await _storeOf(controller).load('standings'), {
        'pct': '1',
        'paper': 'a4',
      });

      await controller.resetAll();
      // The view state is fresh: filters, options, paper, preview, pages.
      expect(controller.params.filters, isEmpty);
      expect(controller.params.paper, isNull);
      expect(controller.params.preview, isFalse);
      expect(controller.params.printPages, isEmpty);
      expect(controller.params.previewExplicit, isFalse);
      expect(controller.params.printPagesExplicit, isFalse);
      // The zoom stays.
      expect(controller.params.zoom, 1.25);
      // Only this kind's entry is forgotten; another report's stays.
      final store = _storeOf(controller);
      expect(await store.load('standings'), isEmpty);
      expect(await store.load('matrix'), {'cmp': '1'});
      expect(controller.filters['pct'], isNull);
    },
  );

  test(
    'the empty-state reset clears the URL filters and keeps the options',
    () async {
      final controller = await _controller(
        stored: {
          'standings': {'pct': '1'},
        },
        initial: ReportViewParams.fromQuery(const {'f.from': '2', 'f.to': '1'}),
      );
      expect(controller.check, isA<ReportInvalid>());

      controller.resetFilters();
      expect(controller.check, isNot(isA<ReportInvalid>()));
      // The stored option still applies after the URL filters are cleared.
      expect(controller.filters['pct'], '1');
      final store = _storeOf(controller);
      expect(await store.load('standings'), {'pct': '1'});
    },
  );
}

/// The store the controller writes to: the one given to it.
ReportOptionsStore _storeOf(ReportViewerController controller) {
  final options = controller.options;
  expect(options, isNotNull);
  return options!;
}
