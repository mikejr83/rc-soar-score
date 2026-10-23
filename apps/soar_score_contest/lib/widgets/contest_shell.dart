import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';
import '../services/workspace/workspace_control_target.dart';
import 'app_window_title.dart';
import 'contest_name_loader.dart';
import 'contest_status_bar.dart';
import 'shell_destinations.dart';
import 'shell_header.dart';
import 'shell_round_loader.dart';
import 'shell_rail.dart';
import 'shell_status_panel.dart';
import 'sync/shell_sync_status.dart';
import 'workspace/workspace_focus_link.dart';

/// The persistent contest-administration shell (Material 3 rail-first
/// layout):
///
/// - a full-height [ShellRail] on the leading edge with the title and
///   route-dependent destinations,
/// - a content pane with a slim [ShellHeader] (naming the selected page) and,
///   in the contest scope, a [ShellStatusPanel] above the route's [child],
/// - a [ContestStatusBar] spanning the full window width at the bottom.
///
/// The window title names the selected contest, when there is one.
///
/// The shell wraps the main page and every route below it, plus the
/// contest-scoped routes. The landing page is outside the shell.
class ContestShell extends StatefulWidget {
  const ContestShell({super.key, required this.state, required this.child});

  /// The matched route state; drives the rail's destinations and the
  /// header's breadcrumb/back arrow.
  final GoRouterState state;

  final Widget child;

  @override
  State<ContestShell> createState() => _ContestShellState();
}

class _ContestShellState extends State<ContestShell> {
  // Lets the status panel reach the workspace page when it is the page shown.
  final WorkspaceFocusLink _focusLink = WorkspaceFocusLink();

  // On the workspace the panel focuses the control directly; from any other
  // contest page it opens the workspace on that control, and the workspace
  // does the focus once loaded.
  void _openControl(String? contestId, WorkspaceControlTarget target) {
    final animate = !MediaQuery.disableAnimationsOf(context);
    if (_focusLink.isAttached) {
      _focusLink.focus(target, animate: animate);
    } else if (contestId != null) {
      context.go(contestWorkspacePathFor(contestId, target));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final child = widget.child;
    final path = state.uri.path;

    // The loader stays in the tree in both scopes so the routed child keeps
    // its place (and state) when entering or leaving a contest.
    return ContestNameLoader(
      contestId: contestIdFor(path),
      builder: (context, contest) => AppWindowTitle(
        title: windowTitleFor(contestName: contest?.name),
        child: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ShellRail(path: path),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ShellHeader(path: path, contestName: contest?.name),
                          const Divider(height: 1, thickness: 1),
                          if (contest != null) ...[
                            ShellRoundLoader(
                              contest: contest,
                              path: path,
                              builder: (context, round) => ShellStatusPanel(
                                contest: contest,
                                trailing: ShellSyncStatus(contest: contest),
                                onOpen: (target) =>
                                    _openControl(contest.id.value, target),
                                round: round,
                                onOpenRound: (item) => context.go(
                                  contestScoringPath(
                                    contest.id.value,
                                    round: item.round,
                                    group: item.group,
                                  ),
                                ),
                              ),
                            ),
                            const Divider(height: 1, thickness: 1),
                          ],
                          Expanded(
                            child: WorkspaceFocusLinkScope(
                              link: _focusLink,
                              child: child,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const ContestStatusBar(),
            ],
          ),
        ),
      ),
    );
  }
}
