import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../services/workspace/workspace_layout_plan.dart';
import '../workspace_frame.dart';

/// The workspace while the contest loads: the page frame with placeholder
/// blocks, so the layout does not jump when the data arrives, and a thin
/// progress bar. Says "Loading contest" politely.
class WorkspaceLoadingSkeleton extends StatefulWidget {
  const WorkspaceLoadingSkeleton({super.key});

  @override
  State<WorkspaceLoadingSkeleton> createState() =>
      _WorkspaceLoadingSkeletonState();
}

class _WorkspaceLoadingSkeletonState extends State<WorkspaceLoadingSkeleton> {
  final ScrollController _scroll = ScrollController();

  // The lifecycle is not known yet; the early states have the fewest
  // sections and the page settles from there.
  final WorkspaceLayoutPlan _plan = WorkspaceLayoutPlan.of(
    lifecycle: LifecycleState.configuring,
    hasMatrix: false,
    hasAttentionItems: false,
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Loading contest',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A determinate bar when motion is reduced, so nothing animates.
          LinearProgressIndicator(
            key: const ValueKey('workspace-loading-bar'),
            value: reduceMotion ? 0.4 : null,
            minHeight: 3,
          ),
          Expanded(
            child: ExcludeSemantics(
              child: WorkspaceFrame(
                plan: _plan,
                scrollController: _scroll,
                sectionBuilder: (section) => const _Block(height: 120),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
  );
}
