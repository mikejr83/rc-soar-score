import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../reports_facts.dart';
import '../reports_facts_loader.dart';
import 'page_setup.dart';
import 'report_print_result.dart';
import 'report_spec.dart';
import 'report_view_params.dart';

/// Where the viewer is in getting the data a report is built from.
enum ViewerLoad { loading, ready, unavailable, notFound }

/// A short message with an optional action, shown as a snackbar.
class ViewerNotice {
  const ViewerNotice(this.message, {this.actionLabel});

  final String message;
  final String? actionLabel;
}

/// The state behind the report viewer: the data, the filters, the page setup
/// and the print flow. Filter changes apply at once; there is no Apply step.
///
/// An open report never redraws on its own when the contest changes. With a
/// [pollInterval] the controller checks now and then and sets [outdated];
/// [refresh] is the only thing that replaces the sheet's data.
class ReportViewerController extends ChangeNotifier {
  ReportViewerController({
    required this.client,
    required this.contestId,
    required this.spec,
    required this.defaultPaper,
    required this.printer,
    ReportViewParams initial = const ReportViewParams(),
    this.pollInterval,
    this.onParams,
  }) : _params = initial;

  final ApiClient? client;

  /// `null` when the route's id is not an id.
  final Id? contestId;
  final ReportSpec spec;
  final PaperSize defaultPaper;
  final ReportPrinter printer;
  final Duration? pollInterval;

  /// Told whenever the params change, so the page can keep the URL current.
  final ValueChanged<ReportViewParams>? onParams;

  ViewerLoad _load = ViewerLoad.loading;
  ReportsFacts? _facts;
  ReportViewParams _params;
  Map<String, String>? _lastGood;
  bool _outdated = false;
  bool _refreshing = false;
  bool _printFailed = false;
  bool _busy = false;
  ViewerNotice? _notice;
  Timer? _timer;
  bool _disposed = false;

  // The report's own data and the filters it was read for. A change to the
  // data key waits for the new data before the sheet changes; any other change
  // applies at once.
  Object? _data;
  String? _dataKey;
  Map<String, String>? _shown;
  bool _dataLoading = false;
  bool _dataFailed = false;
  int _dataToken = 0;

  ViewerLoad get load => _load;
  ReportsFacts? get facts => _facts;
  ReportViewParams get params => _params;
  bool get outdated => _outdated;

  /// A refresh is under way; the sheet stays and dims slightly.
  bool get refreshing => _refreshing;
  bool get printFailed => _printFailed;

  /// A print or PDF job is being prepared; a second request is ignored.
  bool get busy => _busy;
  ViewerNotice? get notice => _notice;

  /// The report's own data; `null` for a report with none, or before it loads.
  Object? get data => _data;

  /// Whether the report reads data of its own.
  bool get usesData {
    final facts = _facts;
    return facts != null && spec.dataKey(_currentFilters(), facts) != null;
  }

  /// The first read of the report's data is under way: nothing to show yet.
  bool get dataPending =>
      usesData && _data == null && !_dataFailed && check is! ReportEmpty;

  /// The server has nothing to build the sheet from yet.
  ReportNoData? get noData =>
      _data is ReportNoData ? _data as ReportNoData : null;

  /// A later read is under way; the last good sheet stays, dimmed.
  bool get generating => _dataLoading && _data != null;

  /// The last read of the report's data failed.
  bool get dataFailed => _dataFailed;

  PageSetup get setup => PageSetup(
    _params.paper ?? defaultPaper,
    _params.orientation ?? spec.defaultOrientation,
  );

  /// The filters in force: the URL's over the report's defaults.
  Map<String, String> get filters => _filtersFor(_facts);

  Map<String, String> _filtersFor(ReportsFacts? facts) => {
    if (facts != null) ...spec.defaultFilters(facts),
    ..._params.filters,
  };

  ReportCheck get check {
    final facts = _facts;
    return facts == null ? ReportCheck.ok : spec.check(filters, facts);
  }

  bool get isInvalid => check is ReportInvalid;

  /// The filters to build from for [facts]: the current ones, or the last
  /// good ones while the current ones are invalid.
  Map<String, String> _currentFiltersFor(ReportsFacts? facts) {
    final current = _filtersFor(facts);
    final invalid =
        facts != null && spec.check(current, facts) is ReportInvalid;
    if (invalid) {
      return _lastGood ?? {...spec.defaultFilters(facts)};
    }
    return current;
  }

  Map<String, String> _currentFilters() => _currentFiltersFor(_facts);

  /// The filters the sheet is built from: the current ones, or the last good
  /// ones while the current ones are invalid; for a report with data of its
  /// own, the ones its data was read for.
  Map<String, String> get sheetFilters => _shown ?? _currentFilters();

  /// Whether the sheet has anything to print.
  bool get hasSheet =>
      _load == ViewerLoad.ready &&
      check is! ReportEmpty &&
      (!usesData || _data != null) &&
      noData == null;

  // Loading.

  Future<void> start() async {
    await _fetch();
    final interval = pollInterval;
    if (interval != null && !_disposed) {
      _timer = Timer.periodic(interval, (_) => unawaited(_poll()));
    }
  }

  Future<ReportsFacts> _read() {
    final api = client;
    final id = contestId;
    if (api == null) {
      return Future.error(StateError('No API client is available.'));
    }
    if (id == null) {
      return Future.error(const _NotAnId());
    }
    return ReportsFactsLoader.load(api, id);
  }

  Future<void> _fetch() async {
    try {
      final facts = await _read();
      _facts = facts;
      _load = ViewerLoad.ready;
      _outdated = false;
      _remember();
      _changed();
      await _syncData(force: true);
      return;
    } on _NotAnId {
      _load = ViewerLoad.notFound;
    } on ApiHttpError catch (error) {
      _load = error.statusCode == 404
          ? ViewerLoad.notFound
          : ViewerLoad.unavailable;
    } on Object {
      _load = ViewerLoad.unavailable;
    }
    _changed();
  }

  /// Tries again after a failed read; the filters in the URL are kept.
  Future<void> retry() async {
    _load = ViewerLoad.loading;
    _changed();
    await _fetch();
  }

  Future<void> _poll() async {
    if (_load != ViewerLoad.ready || _outdated || _refreshing) {
      return;
    }
    try {
      final fresh = await _read();
      if (fresh.fingerprint != _facts?.fingerprint && !_disposed) {
        _outdated = true;
        _changed();
      }
    } on Object {
      // A failed check says nothing; the sheet stays as it is.
    }
  }

  /// Reads the data again and replaces the sheet's. Only ever on request.
  ///
  /// The facts and the report's own data are replaced together or not at all:
  /// when the new data cannot be read the old sheet stays as it was, still
  /// marked out of date, so it never mixes two snapshots.
  Future<void> refresh() async {
    _refreshing = true;
    _changed();
    try {
      final fresh = await _read();
      if (await _syncData(force: true, candidate: fresh)) {
        _outdated = false;
        _remember();
      }
    } on Object {
      // Keep the old sheet; the banner stays so the director can try again.
    }
    _refreshing = false;
    _changed();
  }

  // Filters and page setup.

  void _remember() {
    if (!isInvalid && _facts != null) {
      _lastGood = filters;
    }
  }

  void _setParams(ReportViewParams params) {
    _params = params;
    _remember();
    onParams?.call(params);
    _changed();
    unawaited(_syncData());
  }

  /// Reads the report's data again when the filters now need other data (or
  /// [force]), or applies the filters at once when they do not. With a
  /// [candidate] snapshot of the facts it commits the facts only together with
  /// the data read for them. Completes with whether it did.
  Future<bool> _syncData({bool force = false, ReportsFacts? candidate}) async {
    final facts = candidate ?? _facts;
    final api = client;
    final id = contestId;
    if (facts == null || api == null || id == null) {
      return false;
    }
    final filters = _currentFiltersFor(facts);
    final key = spec.dataKey(filters, facts);
    if (key == null) {
      if (candidate != null) {
        _facts = candidate;
      }
      _shown = null;
      return true;
    }
    if (!force && key == _dataKey && _data != null) {
      _shown = filters;
      _changed();
      return true;
    }
    final token = ++_dataToken;
    _dataLoading = true;
    _dataFailed = false;
    _changed();
    try {
      final data = await spec.loadData(
        ReportDataRequest(
          client: api,
          contestId: id,
          facts: facts,
          filters: filters,
        ),
      );
      if (token != _dataToken || _disposed) {
        return false;
      }
      _data = switch (data) {
        ReportLoaded(:final data) => data,
        final ReportNoData none => none,
        ReportNothingToLoad() => null,
      };
      _dataKey = key;
      if (candidate != null) {
        _facts = candidate;
      }
      _shown = _currentFilters();
    } on Object {
      if (token != _dataToken || _disposed) {
        return false;
      }
      // A refresh that cannot read its data leaves the old snapshot alone.
      _dataFailed = candidate == null;
      _dataLoading = false;
      _changed();
      return false;
    }
    _dataLoading = false;
    _changed();
    return true;
  }

  /// Reads the report's data again after a failure.
  Future<void> retryData() => _syncData(force: true);

  void setFilter(String key, String value) =>
      _setParams(_params.copyWith(filters: {..._params.filters, key: value}));

  void setFilters(Map<String, String> changes) =>
      _setParams(_params.copyWith(filters: {..._params.filters, ...changes}));

  void resetFilters() => _setParams(_params.copyWith(filters: const {}));

  void setPaper(PaperSize paper) => _setParams(_params.copyWith(paper: paper));

  void setOrientation(PageOrientation orientation) =>
      _setParams(_params.copyWith(orientation: orientation));

  void setPreview(bool preview) =>
      _setParams(_params.copyWith(preview: preview));

  /// The pages to print or save, as typed; empty for every page.
  void setPrintPages(String pages) =>
      _setParams(_params.copyWith(printPages: pages));

  /// A fixed zoom, or `null` to fit the width.
  void setZoom(double? zoom) => _setParams(_params.copyWith(zoom: () => zoom));

  // Printing.

  /// Opens the platform's print dialog for a sheet of [pageCount] pages.
  Future<void> print(String title, List<Widget> pages) =>
      _send(title, pages, pdf: false);

  Future<void> savePdf(String title, List<Widget> pages) =>
      _send(title, pages, pdf: true);

  Future<void> _send(
    String title,
    List<Widget> pages, {
    required bool pdf,
  }) async {
    if (_busy) {
      return;
    }
    _busy = true;
    _printFailed = false;
    // Painting the pages takes the UI thread for a while: say so, and let the
    // message reach the screen first.
    _notice = const ViewerNotice('Preparing the pages…');
    _changed();
    await WidgetsBinding.instance.endOfFrame;
    final pageCount = pages.length;
    final job = ReportPrintJob(title: title, setup: setup, pages: pages);
    final ReportPrintResult result;
    try {
      result = pdf ? await printer.savePdf(job) : await printer.print(job);
    } finally {
      _busy = false;
    }
    if (_disposed) {
      return;
    }
    final pageText = '$pageCount ${pageCount == 1 ? 'page' : 'pages'}';
    switch (result) {
      case ReportPrintResult.sent:
        _notice = ViewerNotice(
          pdf
              ? 'PDF saved · ${printer.lastSavedName ?? '$title.pdf'}'
              : 'Sent to the printer · $pageText, ${job.paperLabel}, '
                    '${job.orientationLabel.toLowerCase()}.',
        );
      case ReportPrintResult.cancelled:
        _notice = ViewerNotice(
          pdf
              ? 'Save cancelled. Nothing changed.'
              : 'Print cancelled. Nothing changed.',
          actionLabel: pdf ? 'Save again' : 'Print again',
        );
      case ReportPrintResult.failed:
        _printFailed = true;
        _notice = null;
      case ReportPrintResult.unknown:
        _notice = null;
      case ReportPrintResult.notWired:
        _notice = ViewerNotice(
          pdf
              ? 'Save as PDF isn’t wired up yet.'
              : 'Printing isn’t wired up yet.',
        );
    }
    _changed();
  }

  void dismissPrintFailure() {
    _printFailed = false;
    _changed();
  }

  void clearNotice() {
    if (_notice != null) {
      _notice = null;
      _changed();
    }
  }

  void _changed() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

/// The route's contest id is not an id.
class _NotAnId implements Exception {
  const _NotAnId();
}
