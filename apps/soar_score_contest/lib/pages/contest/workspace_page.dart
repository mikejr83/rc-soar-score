import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_api/soar_score_api.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:logging/logging.dart';

import '../../api_client_provider.dart';
import '../../router.dart';
import '../../ui_account_provider.dart';
import '../../connectivity_provider.dart';
import '../../services/competition_import/competition_import.dart';
import '../../services/workspace/attention/needs_attention.dart';
import '../../services/workspace/next_step/completion_dismissals.dart';
import '../../services/workspace/workspace_control.dart';
import '../../services/workspace/workspace_facts.dart';
import '../../services/workspace/workspace_control_target.dart';
import '../../services/workspace/workspace_facts_loader.dart';
import '../../services/workspace/workspace_layout_plan.dart';
import '../../services/workspace/workspace_page_state.dart';
import '../../services/workspace/workspace_section.dart';
import '../../widgets/api_error_text.dart';
import '../../widgets/contest_scope.dart';
import '../../widgets/workspace/activity/recent_activity_section.dart';
import '../../widgets/workspace/attention/attention_section.dart';
import '../../widgets/workspace/checklist/setup_checklist_section.dart';
import '../../widgets/workspace/controls/archive_control_card.dart';
import '../../widgets/workspace/controls/publication_control_card.dart';
import '../../widgets/workspace/controls/results_control_card.dart';
import '../../widgets/workspace/controls/status_summary_card.dart';
import '../../widgets/workspace/controls/transition_control_card.dart';
import '../../widgets/workspace/next_step/next_step_section.dart';
import '../../widgets/workspace/progress/progress_section.dart';
import '../../widgets/workspace/workspace_control_slot.dart';
import '../../widgets/workspace/workspace_facts_details.dart';
import '../../widgets/workspace/states/workspace_load_failed_view.dart';
import '../../widgets/workspace/states/workspace_loading_skeleton.dart';
import '../../widgets/workspace/states/workspace_not_found_view.dart';
import '../../widgets/workspace/workspace_banners.dart';
import '../../widgets/workspace/workspace_focus_controller.dart';
import '../../widgets/workspace/workspace_focus_link.dart';
import '../../widgets/workspace/workspace_frame.dart';
import '../../widgets/workspace/workspace_live_region.dart';
import '../../widgets/workspace/workspace_scope.dart';
import '../../widgets/workspace/workspace_section_slot.dart';

final _logger = Logger('ContestWorkspacePage');

DateTime _systemClock() => DateTime.now().toUtc();

/// The contest workspace for one contest (`plan/ui/contest-administration/
/// contest-workspace.md`): a frame of section slots arranged by
/// [WorkspaceLayoutPlan]. The name lives in the shell header and the status
/// values in the shell's status panel.
class ContestWorkspacePage extends StatefulWidget {
  const ContestWorkspacePage({
    super.key,
    required this.contestId,
    this.clock = _systemClock,
    this.initialFocus,
  });

  /// The selected contest's id, taken from the route.
  final String contestId;

  /// The control to take the director to once the page has loaded, from the
  /// route's fragment (`#administration`).
  final WorkspaceControlTarget? initialFocus;

  /// The current time for the next-step card, injectable for tests.
  final DateTime Function() clock;

  @override
  State<ContestWorkspacePage> createState() => _ContestWorkspacePageState();
}

class _ContestWorkspacePageState extends State<ContestWorkspacePage> {
  // Only used outside a shell. Inside one, the contest comes from the
  // [ContestScope] so a refresh is a single request.
  Future<Contest>? _contest;
  final ScrollController _scroll = ScrollController();
  String _announcement = '';

  // The facts behind the sections, loaded once the contest is known and again
  // whenever the contest changes. A failed load leaves the page on its default
  // layout rather than hiding it.
  WorkspaceFacts? _facts;
  Contest? _factsFor;
  bool _factsFailed = false;
  final CompletionDismissals _dismissals = CompletionDismissals();

  // What a rejected change was about, while the stale-page banner shows.
  String? _staleWhat;
  ImportedContestNote? _importNote;

  // The contest the page last showed ready. A failed reload keeps it on
  // screen (with the stale banner, if one is up) instead of replacing the
  // workspace with the load-failed view.
  Contest? _shown;

  // Scrolls to, focuses and highlights a control; the shell's status panel
  // reaches it through [WorkspaceFocusLink].
  final WorkspaceFocusController _focus = WorkspaceFocusController();
  WorkspaceFocusLink? _link;
  WorkspaceControlTarget? _pendingFocus;

  @override
  void initState() {
    super.initState();
    _pendingFocus = widget.initialFocus;
    _focus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final link = WorkspaceFocusLinkScope.maybeOf(context);
    if (link != _link) {
      _link?.detach(_focus);
      _link = link?..attach(_focus);
    }
    if (ContestScope.maybeOf(context) == null) {
      _contest ??= _load();
    }
  }

  @override
  void didUpdateWidget(ContestWorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFocus != null &&
        widget.initialFocus != oldWidget.initialFocus) {
      _pendingFocus = widget.initialFocus;
    }
    if (oldWidget.contestId != widget.contestId &&
        ContestScope.maybeOf(context) == null) {
      _contest = _load();
    }
  }

  @override
  void dispose() {
    _link?.detach(_focus);
    _focus
      ..removeListener(_onFocusChanged)
      ..dispose();
    _scroll.dispose();
    super.dispose();
  }

  // Until the facts loader (#342) lands, the contest is the only thing the
  // page loads; this is the one seam to widen then.
  Future<Contest> _load() {
    final client = apiClientOf(context);
    if (client == null) {
      return Future.error(StateError('No API client is available.'));
    }
    try {
      final contest = client.contest(Id.parse(widget.contestId));
      // The builder subscribes on the next frame; see ContestNameLoader.
      contest.ignore();
      return contest;
    } on ArgumentError {
      return Future.error(StateError('"${widget.contestId}" is not an id.'));
    }
  }

  // Reloads the contest and the facts, not the shell. The stale banner stays
  // until the reload succeeds; a failed one leaves the page and the banner as
  // they were. The sections stay mounted, so the scroll position is kept.
  void _tryAgain() {
    _refresh().then((ok) {
      if (!mounted) {
        return;
      }
      if (ok) {
        setState(() {
          _staleWhat = null;
        });
      }
      _reloadFacts();
    });
  }

  void _reportStale(String what) {
    setState(() {
      _staleWhat = what;
    });
  }

  /// Reloads the contest, which also updates the shell's status panel.
  /// Completes with whether the reload succeeded.
  Future<bool> _refresh() async {
    final scope = ContestScope.maybeOf(context);
    if (scope != null) {
      return scope.reload();
    }
    final contest = _load();
    setState(() {
      _contest = contest;
    });
    try {
      await contest;
      return true;
    } on Object {
      // The builder shows the failure; the caller only waits.
      return false;
    }
  }

  /// Loads the facts again for the same contest, for a Retry.
  void _reloadFacts() {
    final contest = _factsFor;
    if (contest == null) {
      return;
    }
    setState(() {
      _factsFailed = false;
    });
    _factsFor = null;
    _ensureFacts(contest);
  }

  /// The note on a contest that came from GliderScore. Only the native build
  /// keeps import records, so elsewhere there is none.
  Future<void> _loadImportNote(Contest contest) async {
    final store = CompetitionImportStore.current;
    if (store == null) {
      return;
    }
    try {
      final note = await store.noteFor(contest.id);
      if (mounted && _factsFor == contest && note != _importNote) {
        setState(() => _importNote = note);
      }
    } catch (_) {
      // The note is a courtesy; the page works without it.
    }
  }

  void _ensureFacts(Contest contest) {
    if (_factsFor == contest) {
      return;
    }
    _factsFor = contest;
    _loadImportNote(contest);
    final client = apiClientOf(context);
    if (client == null) {
      return;
    }
    final monitor = appConnectivityOf(context);
    final offline = monitor?.internetStatus == ConnectivityStatus.unavailable;
    WorkspaceFactsLoader.load(
      client,
      contest,
      isOffline: offline,
      actingAccountId: uiAccountIdOf(context),
    ).then(
      (facts) {
        _logger.info(
          'Successfully loaded workspace facts for contest ${contest.id}',
        );
        if (mounted && _factsFor == contest) {
          _logger.info(
            'Workspace facts for contest ${contest.id} are ready to be applied.',
          );
          setState(() {
            _facts = facts;
            _factsFailed = false;
          });
        } else {
          _logger.info(
            'Workspace facts for contest ${contest.id} were loaded but the widget is no longer mounted or the contest has changed.',
          );
        }
      },
      onError: (Object _) {
        _logger.warning(
          'Failed to load workspace facts for contest ${contest.id}',
        );
        if (mounted && _factsFor == contest) {
          setState(() {
            _facts = null;
            _factsFailed = true;
          });
        }
      },
    );
  }

  // Runs the focus asked for by the route once the controls are on the page.
  // A control that is not there (a failure state, say) drops the request
  // without a message.
  void _runPendingFocus() {
    final target = _pendingFocus;
    if (target == null) {
      return;
    }
    _pendingFocus = null;
    _focus.focus(target, animate: !MediaQuery.disableAnimationsOf(context));
  }

  void _announce(String message) {
    setState(() {
      _announcement = message;
    });
  }

  bool get _validId {
    try {
      Id.parse(widget.contestId);
      return true;
    } on ArgumentError {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = ContestScope.maybeOf(context);
    if (scope == null) {
      return FutureBuilder<Contest>(
        future: _contest,
        builder: (context, snapshot) =>
            _body(context, snapshot.data, snapshot.error),
      );
    }
    final Object? error = apiClientOf(context) == null
        ? StateError('No API client is available.')
        : scope.error;
    return _body(context, scope.contest, error);
  }

  Widget _body(BuildContext context, Contest? loaded, Object? error) {
    // A failed reload (anything but "not found") keeps the page on show.
    final notFound = error is ApiHttpError && error.statusCode == 404;
    final kept = _shown;
    final contest =
        loaded ??
        (!notFound && kept != null && kept.id.toString() == widget.contestId
            ? kept
            : null);
    if (loaded != null) {
      _shown = loaded;
    } else if (contest == null) {
      _shown = null;
    }
    final state = WorkspacePageState.of(
      idValid: _validId,
      contest: contest,
      error: error,
      stale: _staleWhat != null,
    );
    return switch (state) {
      WorkspaceLoading() => const WorkspaceLoadingSkeleton(),
      WorkspaceNotFound() => WorkspaceNotFoundView(
        onBack: () => context.go(homePath),
      ),
      WorkspaceLoadFailed(:final error) => WorkspaceLoadFailedView(
        message: apiErrorText(error),
        onRetry: _tryAgain,
      ),
      WorkspaceReady() => _ready(context, contest!),
    };
  }

  Widget _ready(BuildContext context, Contest contest) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ensureFacts(contest);
        _runPendingFocus();
      }
    });
    final monitor = appConnectivityOf(context);
    return ListenableBuilder(
      listenable: monitor ?? Listenable.merge(const []),
      builder: (context, _) {
        final offline =
            monitor?.internetStatus == ConnectivityStatus.unavailable;
        return _frame(contest, offline: offline);
      },
    );
  }

  Widget _frame(Contest contest, {required bool offline}) {
    final readOnly = contest.lifecycleState == LifecycleState.completed;
    final facts = _facts?.withOffline(offline);
    final plan = WorkspaceLayoutPlan.of(
      lifecycle: contest.lifecycleState,
      hasMatrix: facts?.hasMatrix ?? false,
      hasAttentionItems: facts != null && NeedsAttention.of(facts).hasItems,
    );
    return WorkspaceScope(
      refresh: () async {
        await _refresh();
      },
      announce: _announce,
      readOnly: readOnly,
      facts: facts,
      factsFailed: _factsFailed,
      reloadFacts: _reloadFacts,
      reportStale: _reportStale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The unavailable banner (server unreachable, local copy shown)
          // has no source until the local store lands (#319), so it is not
          // wired here; it must not fake a local copy.
          WorkspaceBanners(
            offline: offline,
            staleChange: _staleWhat,
            onRefresh: _tryAgain,
            importNote: _importNote,
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                WorkspaceFrame(
                  plan: plan,
                  scrollController: _scroll,
                  sectionBuilder: (section) => WorkspaceSectionSlot(
                    section: section,
                    readOnly: readOnly,
                    child: _content(section, contest, plan, readOnly),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  child: WorkspaceLiveRegion(message: _announcement),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _content(
    WorkspaceSection section,
    Contest contest,
    WorkspaceLayoutPlan plan,
    bool readOnly,
  ) => switch (section) {
    WorkspaceSection.nextStep => NextStepSection(
      contest: contest,
      dismissals: _dismissals,
      clock: widget.clock,
    ),
    WorkspaceSection.checklist => SetupChecklistSection(contest: contest),
    WorkspaceSection.attention => AttentionSection(contest: contest),
    WorkspaceSection.progress => ProgressSection(contest: contest),
    WorkspaceSection.facts => WorkspaceFactsDetails(contest: contest),
    WorkspaceSection.activity => RecentActivitySection(contest: contest),
    WorkspaceSection.controls => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatusSummaryCard(contest: contest, clock: widget.clock),
        for (var i = 0; i < plan.controls.length; i++) ...[
          const SizedBox(height: 16),
          WorkspaceControlSlot(
            control: plan.controls[i],
            readOnly: readOnly,
            highlighted: _focus.highlighted == plan.controls[i],
            anchor: _focus.anchorFor(plan.controls[i]),
            focusNode: _focus.nodeFor(plan.controls[i]),
            child: _controlContent(contest, plan.controls[i]),
          ),
        ],
      ],
    ),
  };

  Widget? _controlContent(Contest contest, WorkspaceControl control) =>
      switch (control) {
        WorkspaceControl.scoring ||
        WorkspaceControl.administration ||
        WorkspaceControl.lifecycle => TransitionControlCard(
          contest: contest,
          control: control,
        ),
        WorkspaceControl.archive => ArchiveControlCard(contest: contest),
        WorkspaceControl.publication => PublicationControlCard(
          contest: contest,
        ),
        WorkspaceControl.results => ResultsControlCard(
          contest: contest,
          clock: widget.clock,
        ),
      };
}
