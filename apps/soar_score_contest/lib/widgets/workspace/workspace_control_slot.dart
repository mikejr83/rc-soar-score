import 'package:flutter/material.dart';

import '../../services/workspace/workspace_control.dart';

/// The title of a control card.
String workspaceControlLabel(WorkspaceControl control) => switch (control) {
  WorkspaceControl.lifecycle => 'Lifecycle',
  WorkspaceControl.scoring => 'Participant scoring',
  WorkspaceControl.results => 'Overall results',
  WorkspaceControl.administration => 'Administration',
  WorkspaceControl.publication => 'Publication',
  WorkspaceControl.archive => 'Archive',
};

/// One control card on the workspace page: the deep-link target for the status
/// panel (#351) and the home of the controls (#250).
class WorkspaceControlSlot extends StatelessWidget {
  const WorkspaceControlSlot({
    super.key,
    required this.control,
    this.highlighted = false,
    this.readOnly = false,
    this.anchor,
    this.focusNode,
    this.child,
  });

  final WorkspaceControl control;

  /// Shows the deep-link highlight: a 2 dp primary outline on a
  /// `primaryContainer` fill, so it is not colour alone.
  final bool highlighted;

  final bool readOnly;

  /// Identifies the card for scrolling to it (the status panel links, #351).
  final GlobalKey? anchor;

  /// Wraps the card's content, so focus can go to its first action or, when
  /// it has none to focus, to the card itself.
  final FocusNode? focusNode;

  /// The card content; a placeholder when `null`.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      key: anchor,
      container: true,
      label: workspaceControlLabel(control),
      child: Focus(
        focusNode: focusNode,
        skipTraversal: true,
        child: Card(
          key: ValueKey('workspace-control-${control.id}'),
          margin: EdgeInsets.zero,
          color: highlighted ? scheme.primaryContainer : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: highlighted
                ? BorderSide(color: scheme.primary, width: 2)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                child ??
                Text(
                  '${workspaceControlLabel(control)} goes here',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
          ),
        ),
      ),
    );
  }
}
