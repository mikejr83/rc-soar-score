import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../report_kind.dart';
import '../reports_facts.dart';
import '../reports_facts_loader.dart';
import 'page_setup.dart';
import 'report_print_result.dart';
import 'report_options_store.dart';
import 'report_spec.dart';
import 'report_view_params.dart';

/// Where the viewer is in getting the data a report is built from.
enum ViewerLoad { loading, ready, unavailable, notFound }

/// A short message with an optional action, shown as a snackbar.
class ViewerNotice {
  const ViewerNotice(this.message, {this.actionLabel, this.pdf = false});

  final String message;
  final String? actionLabel;

  /// The action tries a PDF save again, not a print.
  final bool pdf;
}

/// The state behind the report viewer: the data, the filters, the page setup
/// and the print flow. Filter changes apply at once; there is no Apply step.
///
/// The options the user changed are remembered per account through
/// [options], shared by every contest: a hard-coded default gives way to the
/// stored choice, which gives way to the URL. A change in the viewer writes
/// the stored choice at once; a value the URL carried but the user did not
/// touch is not written.
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
    this.options,
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

  /// Where the account's remembered options live; `null` keeps them in
  /// memory only.
  final ReportOptionsStore? options;

  ViewerLoad _load = ViewerLoad.loading;
  ReportsFacts? _facts;
  ReportViewParams _params;

  /// This report kind's remembered options, read at [start].
  Map<String, String> _stored = const {};

  /// The options are read before the panel can be touched, so its controls
  /// start from the stored values.
  bool _storedLoaded = false;

  /// The writes of this controller, one behind the other: a save reads the
  /// account's map before it writes one kind's entry, so two saves of the
  /// same kind must not overlap.
  Future<void> _saved = Future<void>.value();
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
    _params.paper ?? _storedPaper ?? defaultPaper,
    _params.orientation ?? _storedOrientation ?? spec.defaultOrientation,
  );

  PaperSize? get _storedPaper {
    final name = _stored['paper'];
    if (name == null) return null;
    return PaperSize.values.where((paper) => paper.name == name).firstOrNull;
  }

  PageOrientation? get _storedOrientation {
    final name = _stored['orient'];
    if (name == null) return null;
    return PageOrientation.values
        .where((orientation) => orientation.name == name)
        .firstOrNull;
  }

  /// Print preview: the viewer's choice, else the stored one, else off.
  bool get preview =>
      _params.previewExplicit ? _params.preview : _stored['preview'] == '1';

  /// The pages to print or save, as typed: the viewer's, else the stored
  /// ones, else every page.
  String get printPages =>
      _params.printPagesExplicit ? _params.printPages : _stored['pp'] ?? '';

  /// The filters in force: the URL's over the remembered options, over the
  /// report's defaults.
  Map<String, String> get filters => _filtersFor(_facts);

  Map<String, String> _filtersFor(ReportsFacts? facts) {
    final defaults = facts == null
        ? const <String, String>{}
        : spec.defaultFilters(facts);
    final optionKeys = _optionKeysByKind[spec.kind]!;
    return {
      ...defaults,
      for (final entry in _stored.entries)
        if (optionKeys.contains(entry.key)) entry.key: entry.value,
      ..._params.filters,
    };
  }

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
    await _loadOptions();
    await _fetch();
    final interval = pollInterval;
    if (interval != null && !_disposed) {
      _timer = Timer.periodic(interval, (_) => unawaited(_poll()));
    }
  }

  /// The account's remembered options for this report kind. The options
  /// panel appears only when the view is ready, so the stored values are in
  /// place before the user can see the controls.
  Future<void> _loadOptions() async {
    final store = options;
    final map = store == null
        ? const <String, Map<String, String>>{}
        : await store.load();
    _stored = Map<String, String>.of(map[spec.kind.key] ?? const {});
    _storedLoaded = true;
    // The stored options now join the view, so the URL carries them too. A
    // params the store already names is deep-equal, so this is a no-op
    // without a store or with a view the link already set.
    _setParams(_params);
    if (!_disposed) {
      _changed();
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
    final merged = _mergeStored(params);
    if (merged == _params) {
      return;
    }
    _params = merged;
    _remember();
    onParams?.call(merged);
    _changed();
    unawaited(_syncData());
  }

  /// The params to keep once the stored options are in place: the stored
  /// options the params carry no explicit choice for join in, so the URL
  /// names what is in force, not only what the link brought.
  ReportViewParams _mergeStored(ReportViewParams params) {
    return params.copyWith(
      filters: {
        ...params.filters,
        if (_stored.isNotEmpty)
          for (final entry in _stored.entries)
            if (_optionKeysByKind[spec.kind]!.contains(entry.key) &&
                !params.filters.containsKey(entry.key))
              entry.key: entry.value,
      },
      paper: params.paper ?? _storedPaper,
      orientation: params.orientation ?? _storedOrientation,
      preview: params.previewExplicit
          ? params.preview
          : _stored['preview'] == '1',
      previewExplicit: params.previewExplicit || _stored.containsKey('preview'),
      printPages: params.printPagesExplicit
          ? params.printPages
          : _stored['pp'] ?? '',
      printPagesExplicit:
          params.printPagesExplicit || _stored.containsKey('pp'),
    );
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

  void setFilter(String key, String value) {
    _setParams(_params.copyWith(filters: {..._params.filters, key: value}));
    if (_isOptionKey(key)) {
      _rememberOption(key, value);
    }
  }

  void setFilters(Map<String, String> changes) {
    _setParams(_params.copyWith(filters: {..._params.filters, ...changes}));
    for (final entry in changes.entries) {
      if (_isOptionKey(entry.key)) {
        _rememberOption(entry.key, entry.value);
      }
    }
  }

  void resetFilters() => _setParams(_params.copyWith(filters: const {}));

  void setPaper(PaperSize paper) {
    _setParams(_params.copyWith(paper: paper));
    _rememberOption('paper', paper.name);
  }

  void setOrientation(PageOrientation orientation) {
    _setParams(_params.copyWith(orientation: orientation));
    _rememberOption('orient', orientation.name);
  }

  void setPreview(bool preview) {
    _setParams(_params.copyWith(preview: preview, previewExplicit: true));
    _rememberOption('preview', preview ? '1' : '0');
  }

  /// The pages to print or save, as typed; empty for every page.
  void setPrintPages(String pages) {
    _setParams(_params.copyWith(printPages: pages, printPagesExplicit: true));
    _rememberOption('pp', pages);
  }

  /// The overflow menu's "Reset filters and options": clears the view's
  /// state — the filters, the options, the paper, the orientation, the
  /// preview and the pages to print (the zoom stays) — and forgets the
  /// stored options of this report kind.
  Future<void> resetAll() async {
    _stored = const {};
    _setParams(ReportViewParams(zoom: _params.zoom));
    final reset = _saved.then(
      (_) => options?.reset(spec.kind.key) ?? Future<void>.value(),
    );
    _saved = reset;
    return reset;
  }

  // Remembered options.

  /// The option keys of this report kind, besides the round ranges and the
  /// pilot choice, which are filtering and stay in the URL only.
  static const Map<ReportKind, Set<String>> _optionKeysByKind = {
    ReportKind.standings: {'pct', 'raw', 'team', 'num', 'cls', 'det', 'prov'},
    ReportKind.matrix: {
      'cmp',
      'inf',
      'club',
      'fai',
      'nat',
      'team',
      'num',
      'cls',
    },
    ReportKind.sheet: {},
    ReportKind.cards: {'ret', 'pre', 'up', 'mg'},
  };

  bool _isOptionKey(String key) => _optionKeysByKind[spec.kind]!.contains(key);

  /// Remembers [key] as [value] for this report kind and writes the account
  /// map. A change writes even when it equals the default: the stored value
  /// is the user's last explicit choice.
  void _rememberOption(String key, String value) {
    if (!_storedLoaded) {
      return;
    }
    _stored = {..._stored, key: value};
    unawaited(_saveStored());
  }

  /// Writes the account map for this kind, behind any write of this
  /// controller still in flight.
  Future<void> _saveStored() async {
    final write = _saved;
    final done = write.then(
      (_) => options?.set(spec.kind.key, _stored) ?? Future<void>.value(),
    );
    _saved = done;
    return done;
  }

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
          pdf: pdf,
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
