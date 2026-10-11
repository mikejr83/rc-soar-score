import 'package:flutter/material.dart';

import '../../services/workspace/workspace_layout_plan.dart';
import '../../services/workspace/workspace_section.dart';

/// Content width from which the workspace uses two columns.
const double workspaceTwoColumnMinWidth = 840;

/// Width of the side column in the two-column layout.
const double workspaceSideColumnWidth = 340;

/// The responsive frame of the workspace page: a main and a side column that
/// collapse to one. The breakpoint is the page's own width, not the window's,
/// so it is also right when the rail is expanded.
class WorkspaceFrame extends StatelessWidget {
  const WorkspaceFrame({
    super.key,
    required this.plan,
    required this.sectionBuilder,
    required this.scrollController,
  });

  final WorkspaceLayoutPlan plan;
  final Widget Function(WorkspaceSection section) sectionBuilder;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= workspaceTwoColumnMinWidth;
      final padding = wide ? 24.0 : 16.0;
      return SingleChildScrollView(
        controller: scrollController,
        padding: EdgeInsets.all(padding),
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _column(plan.main)),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: workspaceSideColumnWidth,
                    child: _column(plan.side),
                  ),
                ],
              )
            : _column(plan.single),
      );
    },
  );

  Widget _column(List<WorkspaceSection> sections) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < sections.length; i++) ...[
        if (i > 0) const SizedBox(height: 16),
        sectionBuilder(sections[i]),
      ],
    ],
  );
}
