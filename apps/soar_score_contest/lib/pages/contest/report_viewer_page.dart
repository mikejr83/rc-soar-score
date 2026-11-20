import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../api_client_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../connectivity_provider.dart';
import '../../widgets/invitations/send_invitations_flow.dart';
import '../../local_ui_store_provider.dart';
import '../../router.dart';
import '../../ui_account_provider.dart';
import '../../services/reports/report_availability.dart';
import '../../services/reports/report_kind.dart';
import '../../services/reports/report_launcher.dart';
import '../../services/reports/reports_facts.dart';
import '../../services/reports/result_status.dart';
import '../../services/reports/viewer/page_setup.dart';
import '../../services/reports/viewer/print_page_range.dart';
import '../../services/reports/viewer/report_print_result.dart';
import '../../services/reports/viewer/report_options_store.dart';
import '../../services/reports/viewer/report_spec.dart';
import '../../services/reports/viewer/report_view_params.dart';
import '../../services/reports/viewer/report_viewer_controller.dart';
import '../../widgets/app_window_title.dart';
import '../../widgets/page_states/page_banner.dart';
import '../../widgets/reports/viewer/report_definitions.dart';
import '../../widgets/reports/viewer/report_definition.dart';
import '../../widgets/reports/viewer/report_sheet_area.dart';
import '../../widgets/reports/viewer/report_sheet_page.dart';
import '../../widgets/reports/viewer/viewer_app_bar.dart';
import '../../widgets/reports/viewer/viewer_banner.dart';
import '../../widgets/reports/viewer/viewer_offline_banner.dart';
import '../../widgets/reports/viewer/viewer_panel.dart';
import '../../widgets/reports/viewer/viewer_states.dart';
import '../../widgets/reports/viewer/viewer_toolbar.dart';

/// Finds the definition of a report; a test swaps in its own.
typedef ReportDefinitionFinder = ReportDefinition Function(ReportKind kind);

/// The report viewer: one report shown as paper pages with its filters,
/// options and page setup beside them, ready to print. It sits outside the
/// shell, in its own browser tab or in place, so it carries the report's and
/// the contest's names and holds its state in the URL.
///
/// Printing and Save as PDF go through [printer].
class ReportViewerPage extends StatefulWidget {
  const ReportViewerPage({
    super.key,
    required this.contestId,
    required this.report,
    this.params = const ReportViewParams(),
    this.openedInPlace = false,
    this.definitionFor = reportDefinitionFor,
    required this.printer,
    this.launcher,
    this.onParams,
    this.pollInterval = const Duration(seconds: 30),
    this.clock = DateTime.now,
  });

  final String contestId;

  /// `null` when the route's report is not one of the four.
  final ReportKind? report;

  /// The filters, options and page setup the URL carried.
  final ReportViewParams params;

  /// Opened by navigating the window (no second window), so the viewer offers
  /// Back to Reports.
  final bool openedInPlace;
  final ReportDefinitionFinder definitionFor;
  final ReportPrinter printer;
  final ReportLauncher? launcher;

  /// Called when the params change, so the URL can follow.
  final ValueChanged<ReportViewParams>? onParams;

  /// How often an open report checks whether its data changed; `null` never.
  final Duration? pollInterval;
  final DateTime Function() clock;

  @override
  State<ReportViewerPage> createState() => _ReportViewerPageState();
}

class _ReportViewerPageState extends State<ReportViewerPage> {
  ReportViewerController? _controller;
  ReportDefinition? _definition;
  ReportsFacts? _shownFacts;
  DateTime _generated = DateTime.now();
  double _fit = 1;
  int _page = 1;
  bool _panelOpen = false;
  bool _wasBusy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null || widget.report == null) {
      return;
    }
    final definition = widget.definitionFor(widget.report!);
    Id? id;
    try {
      id = Id.parse(widget.contestId);
    } on ArgumentError {
      id = null;
    }
    final controller = ReportViewerController(
      client: apiClientOf(context),
      publicationClient: publicationClientOf(context),
      contestId: id,
      spec: definition,
      defaultPaper: PaperSize.forLocale(
        Localizations.localeOf(context),
        system: PlatformDispatcher.instance.locale,
      ),
      printer: widget.printer,
      initial: widget.params,
      pollInterval: widget.pollInterval,
      onParams: widget.onParams,
      options: ReportOptionsStore(
        localUiStoreOf(context),
        uiAccountIdOf(context),
      ),
    )..addListener(_onChanged);
    _definition = definition;
    _controller = controller;
    controller.start();
  }

  @override
  void dispose() {
    _controller
      ?..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    final controller = _controller!;
    if (!mounted) {
      return;
    }
    if (!identical(controller.facts, _shownFacts)) {
      _shownFacts = controller.facts;
      _generated = widget.clock();
    }
    setState(() {});
    final notice = controller.notice;
    if (_wasBusy && !controller.busy && notice == null) {
      // The job ended without a message of its own: take the "Preparing"
      // message down.
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
    _wasBusy = controller.busy;
    if (notice != null) {
      controller.clearNotice();
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(notice.message),
            // A snack bar with an action stays until dismissed unless told
            // otherwise; these messages are not worth a click to clear.
            persist: false,
            duration: const Duration(seconds: 8),
            action: notice.actionLabel == null
                ? null
                : SnackBarAction(
                    label: notice.actionLabel!,
                    onPressed: notice.pdf ? _savePdf : _print,
                  ),
          ),
        );
    }
  }

  // Document.

  AppLocalizations get _l10n =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  ReportDocument? _document() {
    final controller = _controller!;
    final facts = controller.facts;
    if (facts == null || !controller.hasSheet) {
      return null;
    }
    final setup = controller.setup;
    return _definition!.build(
      ReportPageContext(
        facts: facts,
        filters: controller.sheetFilters,
        setup: setup,
        bodySize: _definition!.hasRunningFrame
            ? SheetLayout.bodySize(
                setup,
                extraSide: _definition!.extraSideMargin,
              )
            : SheetLayout.bareBodySize(
                setup,
                _definition!.barePageMargins(controller.sheetFilters, facts),
              ),
        preview: controller.preview,
        data: controller.data,
        l10n: _l10n,
        online: invitationsReachable(context),
      ),
    );
  }

  List<Widget> _pages(ReportDocument document) {
    final controller = _controller!;
    final count = document.pages.length;
    final stamp = DateFormat('d MMM y, HH:mm').format(_generated);
    // No calculation version is shown: the contest data the app reads carries
    // none (only a published projection does), and a report is built from the
    // current inputs.
    if (!_definition!.hasRunningFrame) {
      return [
        for (var i = 0; i < count; i++)
          ReportBarePage(
            margins: _definition!.barePageMargins(
              controller.sheetFilters,
              controller.facts!,
            ),
            setup: controller.setup,
            reportName: widget.report!.title,
            pageNumber: i + 1,
            pageCount: count,
            body: document.pages[i],
          ),
      ];
    }
    return [
      for (var i = 0; i < count; i++)
        ReportSheetPage(
          setup: controller.setup,
          title: document.title,
          subtitle: document.subtitle,
          detail: document.detail,
          reportName: widget.report!.title,
          pageNumber: i + 1,
          pageCount: count,
           extraSideMargin: _definition!.extraSideMargin,
           generated: _l10n.viewerGenerated(stamp),
           status: document.status,
          body: document.pages[i],
        ),
    ];
  }

  // Actions.

  String _printTitle() {
    final name = _controller!.facts?.contest.name;
    final title = widget.report!.title;
    return name == null ? title : _l10n.viewerPrintTitle(title, name);
  }

  /// The sheet pages for the printer. They are painted off screen, outside
  /// this widget tree, so they carry the theme and localizations they would
  /// have here.
  List<Widget> _printPages() {
    final pages = _pages(_document()!);
    final range = PrintPageRange.parse(_controller!.printPages, pages.length);
    return [
      for (final number in range.pages)
        Localizations.override(
          context: context,
          child: InheritedTheme.captureAll(context, pages[number - 1]),
        ),
    ];
  }

  /// Whether the typed "Pages to print" is a range of this sheet's pages.
  bool _rangeIsValid(ReportDocument? document) =>
      document == null ||
      PrintPageRange.parse(
        _controller!.printPages,
        document.pages.length,
      ).isValid;

  /// Lets the report remind the director before printing (for example that
  /// some cards have no QR code). Answers whether to go on.
  Future<bool> _confirmPrint() async {
    final gate = _document()?.beforePrint;
    if (gate == null) {
      return true;
    }
    final go = await gate(context);
    return go && mounted;
  }

  Future<void> _print() async {
    final controller = _controller!;
    if (controller.busy ||
        !controller.hasSheet ||
        !controller.printer.capabilities.canPrint) {
      return;
    }
    if (!_rangeIsValid(_document()) || !await _confirmPrint()) {
      return;
    }
    // The pages are built after the reminder: sending invitations from it adds
    // QR codes to the cards.
    controller.print(_printTitle(), _printPages());
  }

  Future<void> _savePdf() async {
    final controller = _controller!;
    if (controller.busy ||
        !controller.hasSheet ||
        !controller.printer.capabilities.canSavePdf) {
      return;
    }
    if (!_rangeIsValid(_document()) || !await _confirmPrint()) {
      return;
    }
    controller.savePdf(_printTitle(), _printPages());
  }

  void _goBack() => context.go(contestReportsPath(widget.contestId));

  void _openPath(String path) =>
      (widget.launcher ?? ReportLaunchers.current).open(context, path);

  /// A link to this report with the view in force: the route with every filter,
  /// option and page setup the URL now carries. On the web the router uses
  /// the hash strategy, so the route goes into the fragment of this window's
  /// URL; anywhere else the app is the window and the route is the whole link.
  String _copyLinkUrl() {
    final report = widget.report!;
    final route = Uri(
      path: contestReportPath(widget.contestId, report),
      queryParameters: {
        ..._controller!.params.toQuery(),
        if (widget.openedInPlace) 'back': '1',
      },
    );
    if (!kIsWeb) {
      return route.toString();
    }
    final base = Uri.base;
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: base.path,
      fragment: route.toString(),
    ).toString();
  }

  void _openAction(ReportAction action) =>
      _openPath(switch (action.destination) {
        ReportDestination.scoring => contestScoringPath(
          widget.contestId,
          round: action.round,
        ),
        ReportDestination.matrix => contestMatrixPath(widget.contestId),
      });

  Future<void> _openFilterSheet() {
    final l10n = _l10n;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .8,
        maxChildSize: .9,
        builder: (context, scroll) => ListenableBuilder(
          listenable: _controller!,
          builder: (context, _) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.viewerFilterOptions,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.viewerDone),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _groups(columns: 1),
            ],
          ),
        ),
      ),
    );
  }

  // Pieces.

  Widget _groups({required int columns}) {
    final controller = _controller!;
    final facts = controller.facts!;
    final setup = controller.setup;
    return ViewerPanelGroups(
      groups: _definition!.controls(
        ReportControlsContext(
          filters: controller.filters,
          facts: facts,
          check: controller.check,
          setFilter: controller.setFilter,
          setFilters: controller.setFilters,
          setup: setup,
          data: controller.data,
          l10n: _l10n,
        ),
      ),
      setup: setup,
      locale: Localizations.localeOf(context),
      preview: controller.preview,
      onPaper: controller.setPaper,
      onOrientation: controller.setOrientation,
      onPreview: controller.setPreview,
      defaultOrientation: controller.suggestedOrientation,
      columns: columns,
      showOrientation: !_definition!.fixedOrientation,
      pageCount: _document()?.pages.length ?? 0,
      printPages: controller.printPages,
      onPrintPages: controller.setPrintPages,
    );
  }

  List<Widget> _banners(ReportDocument? document) {
    final l10n = _l10n;
    final controller = _controller!;
    final printer = controller.printer;
    final banners = <Widget>[];
    final status = document?.status;
    if (status == ResultStatus.official) {
      banners.add(
        ViewerBanner(
          kind: ViewerBannerKind.official,
          icon: Icons.verified,
          lead: l10n.viewerOfficialLead,
            text: document?.statusReason ?? l10n.viewerOfficialDefault,
        ),
      );
    } else if (status == ResultStatus.preliminary) {
      final action = document?.statusAction;
      banners.add(
        ViewerBanner(
          kind: ViewerBannerKind.preliminary,
          icon: Icons.pending,
          lead: l10n.viewerPreliminaryLead,
          text: document?.statusReason ?? l10n.viewerPreliminaryDefault,
          actions: [
            if (action != null)
              PageBannerAction(
                action.label,
                () => _openAction(action),
                emphasis: PageBannerEmphasis.outlined,
              ),
          ],
        ),
      );
    }
    for (final banner in document?.banners ?? const <ReportBanner>[]) {
      banners.add(
        ViewerBanner(
          key: banner.key,
          kind: banner.kind,
          icon: banner.icon,
          lead: banner.lead,
          text: banner.text,
          actions: [
            for (final action in banner.actions)
              PageBannerAction(
                action.label,
                action.onPressed == null
                    ? null
                    : () => action.onPressed!(context),
                emphasis: action.filled
                    ? PageBannerEmphasis.filled
                    : PageBannerEmphasis.outlined,
                key: action.key,
              ),
          ],
          child: banner.busy
              ? const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(),
                )
              : null,
        ),
      );
    }
    if (document?.notice case final notice?) {
      banners.add(
        ViewerBanner(
          kind: ViewerBannerKind.info,
          icon: Icons.view_column,
          lead: l10n.viewerCrowdedLead,
          text: notice,
        ),
      );
    }
    if (controller.outdated) {
      banners.add(
        ViewerBanner(
          kind: ViewerBannerKind.info,
          icon: Icons.update,
          lead: l10n.viewerOutdatedLead,
          text: l10n.viewerOutdatedText,
          actions: [
            PageBannerAction(
              l10n.viewerRefresh,
              controller.refreshing ? null : controller.refresh,
              emphasis: PageBannerEmphasis.filled,
              key: const ValueKey('viewer-refresh'),
            ),
          ],
        ),
      );
    }
    final monitor = appConnectivityOf(context);
    if (monitor?.internetStatus == ConnectivityStatus.unavailable) {
      banners.add(
        ViewerOfflineBanner(
          contestId: controller.facts!.contest.id,
          onOpenSync: () => _openPath(contestSyncPath(widget.contestId)),
        ),
      );
    }
    if (controller.dataFailed) {
      banners.add(
        ViewerBanner(
          kind: ViewerBannerKind.error,
          icon: Icons.error,
          lead: l10n.viewerDataLoadFailedLead,
          text: l10n.viewerDataLoadFailedText,
          actions: [
            PageBannerAction(
              l10n.viewerTryAgain,
              controller.retryData,
              emphasis: PageBannerEmphasis.filled,
              key: const ValueKey('viewer-retry-data'),
            ),
          ],
        ),
      );
    }
    if (controller.printFailed) {
      banners.add(
        ViewerBanner(
          kind: ViewerBannerKind.error,
          icon: Icons.print_disabled,
          lead: l10n.viewerPrintFailedLead,
          text: l10n.viewerPrintFailedText,
          actions: [
            PageBannerAction(
              l10n.viewerSaveAsPdf,
              _savePdf,
              emphasis: PageBannerEmphasis.outlined,
            ),
            PageBannerAction(
              l10n.viewerTryAgain,
              _print,
              emphasis: PageBannerEmphasis.filled,
            ),
          ],
        ),
      );
    }
    final caps = printer.capabilities;
    if (!caps.canPrint) {
      banners.add(
        ViewerBanner(
          kind: ViewerBannerKind.neutral,
          icon: Icons.print_disabled,
          lead: caps.canSavePdf
              ? l10n.viewerPrintingUnavailableLead
              : l10n.viewerPdfUnavailableLead,
          text: caps.canSavePdf
              ? l10n.viewerPrintingUnavailableText
              : l10n.viewerPdfUnavailableText,
          actions: [
            if (!caps.canSavePdf)
              PageBannerAction(
                l10n.viewerCopyLink,
                () => Clipboard.setData(ClipboardData(text: _copyLinkUrl())),
                emphasis: PageBannerEmphasis.filled,
              ),
          ],
        ),
      );
    }
    return banners;
  }

  Widget _body(ReportDocument? document) {
    final controller = _controller!;
    final check = controller.check;
    final setup = controller.setup;
    if (check is ReportEmpty) {
      return ViewerMessage(
        icon: Icons.filter_alt_off,
        title: check.title,
        body: check.body,
        actionLabel: _l10n.viewerClearFilters,
        onAction: controller.resetFilters,
      );
    }
    final noData = controller.noData;
    if (noData != null) {
      return ViewerMessage(
        icon: Icons.insights,
        title: noData.title,
        body: noData.body,
        actionLabel: noData.actionLabel,
        onAction: () => context.go(
          contestScoringPath(widget.contestId, round: noData.round),
        ),
      );
    }
    final pages = _pages(document!);
    return ReportSheetArea(
      setup: setup,
      pages: pages,
      zoom: controller.params.zoom,
      preview: controller.preview,
      dimmed: controller.refreshing || controller.generating,
      onFit: (fit) => setState(() => _fit = fit),
      onPage: (page) => setState(() => _page = page),
    );
  }

  Widget _content(ReportDocument? document) {
    final l10n = _l10n;
    final controller = _controller!;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 600;
    final pageCount = document?.pages.length ?? 0;
    final nothing = document == null;
    final legend = controller.preview
        ? l10n.viewerPrintPreviewLegend
        : compact
        ? l10n.viewerPrintAsShownCompact
        : l10n.viewerPrintAsShown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._banners(document),
        if (!nothing ||
            controller.check is ReportEmpty ||
            controller.noData != null)
          ViewerToolbar(
            pageText: nothing
                ? l10n.viewerNoPages
                : l10n.viewerPageIndicator(_page.clamp(1, pageCount), pageCount),
            legend: nothing ? l10n.viewerNothingToPrint : legend,
            zoom: controller.params.zoom,
            fit: _fit,
            onZoom: controller.setZoom,
            compact: compact,
            onFilters: _openFilterSheet,
            filtersLabel: l10n.viewerFiltersSummary(
              _definition!.filterSummary(controller.filters, controller.facts!),
            ),
          ),
        Expanded(child: _body(document)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final changes = widget.report == null
        ? null
        : _definition?.changesOf(controller?.data);
    if (changes == null) {
      return _buildPage(context);
    }
    return ListenableBuilder(
      listenable: changes,
      builder: (context, _) => _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    final l10n = _l10n;
    final report = widget.report;
    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.viewerReportWord)),
        body: ViewerMessage(
          icon: Icons.search_off,
          title: l10n.viewerUnknownReportTitle,
          body: l10n.viewerUnknownReportBody,
          actionLabel: l10n.viewerBackToReports,
          onAction: _goBack,
        ),
      );
    }
    final controller = _controller!;
    final width = MediaQuery.sizeOf(context).width;
    final expanded = width >= 840;
    final medium = width >= 600 && !expanded;
    final compact = width < 600;
    final facts = controller.facts;
    final contestName = facts?.contest.name ?? '';
    final ready = controller.load == ViewerLoad.ready && facts != null;
    final document = ready ? _document() : null;
    final caps = controller.printer.capabilities;
    final nothing = document == null;
    final rangeOk = _rangeIsValid(document);
    final printEnabled =
        !nothing && !controller.busy && caps.canPrint && rangeOk;
    final pdfEnabled =
        !nothing && !controller.busy && caps.canSavePdf && rangeOk;
    final setup = controller.setup;
    final setupText = nothing
        ? l10n.viewerNothingToPrint
        : !caps.canPrint
        ? l10n.viewerSetupPrintingUnavailable
        : l10n.viewerSetupSummary(
            setup.label,
            document.pages.length,
            document.pages.length == 1 ? 'page' : 'pages',
          );
    final shortcut = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): _print,
        const SingleActivator(LogicalKeyboardKey.keyP, meta: true): _print,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: ViewerAppBar(
            title: report.title,
            contestName: contestName,
            setupText: setupText,
            expanded: expanded,
            compact: compact,
            lead: widget.openedInPlace ? ViewerLead.back : ViewerLead.none,
            onLead: _goBack,
            printEnabled: printEnabled,
            pdfEnabled: pdfEnabled,
            pdfPrimary: !caps.canPrint && caps.canSavePdf,
            onPrint: _print,
            onPdf: _savePdf,
            preview: controller.preview,
            onPreview: controller.setPreview,
            onPageSetup: () {
              if (compact) {
                _openFilterSheet();
              } else {
                setState(() => _panelOpen = true);
              }
            },
            onReset: () => unawaited(controller.resetAll()),
          ),
          body: switch (controller.load) {
            ViewerLoad.loading => ViewerLoading(
              pageAspect: setup.width / setup.height,
            ),
            ViewerLoad.notFound => ViewerMessage(
              icon: Icons.search_off,
              title: l10n.viewerNotFoundTitle,
              body: l10n.viewerNotFoundBody,
              actionLabel: widget.openedInPlace
                  ? l10n.viewerBackToReports
                  : l10n.viewerBackToContests,
              onAction: widget.openedInPlace
                  ? _goBack
                  : () => context.go(homePath),
            ),
            ViewerLoad.unavailable => ViewerMessage(
              icon: Icons.error,
              isError: true,
              title: l10n.viewerUnavailableTitle,
              body: l10n.viewerUnavailableBody,
              actionLabel: l10n.viewerTryAgain,
              onAction: controller.retry,
            ),
            ViewerLoad.ready when controller.dataPending => ViewerLoading(
              pageAspect: setup.width / setup.height,
              label: l10n.viewerBuildingPages,
            ),
            ViewerLoad.ready
                when controller.dataFailed && controller.data == null =>
              ViewerMessage(
                icon: Icons.error,
                isError: true,
                title: l10n.viewerDataUnavailableTitle,
                body: l10n.viewerDataUnavailableBody,
                actionLabel: l10n.viewerTryAgain,
                onAction: controller.retryData,
              ),
            ViewerLoad.ready => _ready(document, expanded, medium),
          },
        ),
      ),
    );
    return AppWindowTitle(
      title: contestName.isEmpty
          ? report.title
          : l10n.viewerPageWindow(report.title, contestName),
      child: shortcut,
    );
  }

  Widget _ready(ReportDocument? document, bool expanded, bool medium) {
    final l10n = _l10n;
    final controller = _controller!;
    final content = _content(document);
    if (expanded) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 320,
            child: _PanelFrame(
              sideEdge: true,
              child: ListView(
                key: const ValueKey('viewer-panel'),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    l10n.viewerFilterOptions,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    l10n.viewerPanelSubtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  _groups(columns: 1),
                ],
              ),
            ),
          ),
          Expanded(child: content),
        ],
      );
    }
    if (medium) {
      final summary = _definition!.filterSummary(
        controller.filters,
        controller.facts!,
      );
      final separator = l10n.viewerPanelSummarySeparator;
      final paperOrientation = [
        '${controller.setup.paper.label}, '
            '${controller.setup.orientation.label.toLowerCase()}',
      ].join(separator);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelFrame(
            sideEdge: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  key: const ValueKey('viewer-panel-toggle'),
                  leading: const Icon(Icons.tune),
                  title: Text(l10n.viewerFilterOptions),
                  subtitle: Text(
                    [
                      if (summary.isNotEmpty) summary,
                      paperOrientation,
                    ].join(separator),
                  ),
                  trailing: Icon(
                    _panelOpen ? Icons.expand_less : Icons.expand_more,
                  ),
                  onTap: () => setState(() => _panelOpen = !_panelOpen),
                ),
                if (_panelOpen)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * .45,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: _groups(columns: 3),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: content),
        ],
      );
    }
    return content;
  }
}

/// The panel's surface: tinted like the app chrome, with a hairline toward the
/// sheet. Screen only.
class _PanelFrame extends StatelessWidget {
  const _PanelFrame({required this.child, required this.sideEdge});

  final Widget child;

  /// The hairline is on the right edge (side panel) or the bottom (bar).
  final bool sideEdge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = BorderSide(color: scheme.outlineVariant);
    // Material paints the tint so list tiles inside can show their ink.
    return Material(
      color: scheme.secondaryContainer,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: sideEdge ? Border(right: line) : Border(bottom: line),
        ),
        child: child,
      ),
    );
  }
}
