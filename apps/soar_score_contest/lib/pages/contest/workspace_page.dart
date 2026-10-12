import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../api_client_provider.dart';
import '../../connectivity_provider.dart';
import '../../services/workspace/next_step/completion_dismissals.dart';
import '../../services/workspace/workspace_facts.dart';
import '../../services/workspace/workspace_facts_loader.dart';
import '../../services/workspace/workspace_layout_plan.dart';
import '../../services/workspace/workspace_section.dart';
import '../../widgets/api_error_text.dart';
import '../../widgets/contest_scope.dart';
import '../../widgets/message_view.dart';
import '../../widgets/workspace/next_step/next_step_section.dart';
import '../../widgets/workspace/workspace_control_slot.dart';
import '../../widgets/workspace/workspace_facts_details.dart';
import '../../widgets/workspace/workspace_frame.dart';
import '../../widgets/workspace/workspace_live_region.dart';
import '../../widgets/workspace/workspace_scope.dart';
import '../../widgets/workspace/workspace_section_slot.dart';

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
  });

  /// The selected contest's id, taken from the route.
  final String contestId;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ContestScope.maybeOf(context) == null) {
      _contest ??= _load();
    }
  }

  @override
  void didUpdateWidget(ContestWorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contestId != widget.contestId &&
        ContestScope.maybeOf(context) == null) {
      _contest = _load();
    }
  }

  @override
  void dispose() {
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
      return client.contest(Id.parse(widget.contestId));
    } on ArgumentError {
      return Future.error(StateError('"${widget.contestId}" is not an id.'));
    }
  }

  void _retry() {
    final scope = ContestScope.maybeOf(context);
    if (scope != null) {
      scope.reload();
      return;
    }
    final contest = _load();
    setState(() {
      _contest = contest;
    });
  }

  /// Reloads the contest, which also updates the shell's status panel.
  Future<void> _refresh() async {
    final scope = ContestScope.maybeOf(context);
    if (scope != null) {
      scope.reload();
      return;
    }
    final contest = _load();
    setState(() {
      _contest = contest;
    });
    try {
      await contest;
    } on Object {
      // The builder shows the failure; the caller only waits.
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

  void _ensureFacts(Contest contest) {
    if (_factsFor == contest) {
      return;
    }
    _factsFor = contest;
    final client = apiClientOf(context);
    if (client == null) {
      return;
    }
    final monitor = appConnectivityOf(context);
    final offline = monitor?.internetStatus == ConnectivityStatus.unavailable;
    WorkspaceFactsLoader.load(client, contest, isOffline: offline).then(
      (facts) {
        if (mounted && _factsFor == contest) {
          setState(() {
            _facts = facts;
            _factsFailed = false;
          });
        }
      },
      onError: (Object _) {
        if (mounted && _factsFor == contest) {
          setState(() {
            _facts = null;
            _factsFailed = true;
          });
        }
      },
    );
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
    final Object? error;
    if (apiClientOf(context) == null) {
      error = StateError('No API client is available.');
    } else if (!_validId) {
      error = StateError('"${widget.contestId}" is not an id.');
    } else {
      error = scope.error;
    }
    return _body(context, scope.contest, error);
  }

  Widget _body(BuildContext context, Contest? contest, Object? error) {
    if (contest == null && error != null) {
      return MessageView(
        text: 'The contest could not be loaded.',
        detail: apiErrorText(error),
        onRetry: _retry,
      );
    }
    if (contest == null) {
      return const Center(child: CircularProgressIndicator());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _ensureFacts(contest);
      }
    });
    final readOnly = contest.lifecycleState == LifecycleState.completed;
    final facts = _facts;
    // The needs-attention list arrives with #345; until then it is empty.
    final plan = WorkspaceLayoutPlan.of(
      lifecycle: contest.lifecycleState,
      hasMatrix: facts?.hasMatrix ?? false,
      hasAttentionItems: false,
    );
    return WorkspaceScope(
      refresh: _refresh,
      announce: _announce,
      readOnly: readOnly,
      facts: facts,
      factsFailed: _factsFailed,
      reloadFacts: _reloadFacts,
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
    WorkspaceSection.facts => WorkspaceFactsDetails(contest: contest),
    WorkspaceSection.controls => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < plan.controls.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          WorkspaceControlSlot(control: plan.controls[i], readOnly: readOnly),
        ],
      ],
    ),
    _ => null,
  };
}
