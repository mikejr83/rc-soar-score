import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_window_title.dart';
import 'contest_name_loader.dart';
import 'contest_status_bar.dart';
import 'shell_destinations.dart';
import 'shell_header.dart';
import 'shell_rail.dart';
import 'shell_status_panel.dart';

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
class ContestShell extends StatelessWidget {
  const ContestShell({super.key, required this.state, required this.child});

  /// The matched route state; drives the rail's destinations and the
  /// header's breadcrumb/back arrow.
  final GoRouterState state;

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
                            ShellStatusPanel(contest: contest),
                            const Divider(height: 1, thickness: 1),
                          ],
                          Expanded(child: child),
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
