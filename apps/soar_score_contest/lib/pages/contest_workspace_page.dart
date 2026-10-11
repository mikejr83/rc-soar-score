import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../api_client_provider.dart';
import '../services/workspace/workspace_layout_plan.dart';
import '../services/workspace/workspace_section.dart';
import '../widgets/api_error_text.dart';
import '../widgets/contest_scope.dart';
import '../widgets/message_view.dart';
import '../widgets/workspace/workspace_control_slot.dart';
import '../widgets/workspace/workspace_facts_details.dart';
import '../widgets/workspace/workspace_frame.dart';
import '../widgets/workspace/workspace_live_region.dart';
import '../widgets/workspace/workspace_scope.dart';
import '../widgets/workspace/workspace_section_slot.dart';

/// The contest workspace for one contest (`plan/ui/contest-administration/
/// contest-workspace.md`): a frame of section slots arranged by
/// [WorkspaceLayoutPlan]. The name lives in the shell header and the status
/// values in the shell's status panel.
class ContestWorkspacePage extends StatefulWidget {
  const ContestWorkspacePage({super.key, required this.contestId});

  /// The selected contest's id, taken from the route.
  final String contestId;

  @override
  State<ContestWorkspacePage> createState() => _ContestWorkspacePageState();
}

class _ContestWorkspacePageState extends State<ContestWorkspacePage> {
  Future<Contest>? _contest;
  final ScrollController _scroll = ScrollController();
  String _announcement = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _contest ??= _load();
  }

  @override
  void didUpdateWidget(ContestWorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contestId != widget.contestId) {
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
    final contest = _load();
    setState(() {
      _contest = contest;
    });
  }

  /// Reloads the page and the shell's copy of the contest, so the status
  /// panel follows a change made here.
  Future<void> _refresh() async {
    ContestScope.maybeOf(context)?.reload();
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

  void _announce(String message) {
    setState(() {
      _announcement = message;
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Contest>(
    future: _contest,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return MessageView(
          text: 'The contest could not be loaded.',
          detail: apiErrorText(snapshot.error!),
          onRetry: _retry,
        );
      }
      final contest = snapshot.data;
      if (contest == null) {
        return const Center(child: CircularProgressIndicator());
      }
      final readOnly = contest.lifecycleState == LifecycleState.completed;
      // No matrix or attention facts yet (#342); the plan shows the
      // lifecycle's default layout until they arrive.
      final plan = WorkspaceLayoutPlan.of(
        lifecycle: contest.lifecycleState,
        hasMatrix: false,
        hasAttentionItems: false,
      );
      return WorkspaceScope(
        refresh: _refresh,
        announce: _announce,
        readOnly: readOnly,
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
    },
  );

  Widget? _content(
    WorkspaceSection section,
    Contest contest,
    WorkspaceLayoutPlan plan,
    bool readOnly,
  ) => switch (section) {
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
