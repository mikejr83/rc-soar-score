import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../services/workspace/workspace_control.dart';

/// The title of a control card.
String workspaceControlLabel(AppLocalizations l10n, WorkspaceControl control) =>
    switch (control) {
      WorkspaceControl.lifecycle => l10n.workspaceControlLifecycle,
      WorkspaceControl.scoring => l10n.workspaceControlScoring,
      WorkspaceControl.results => l10n.workspaceControlResults,
      WorkspaceControl.administration => l10n.workspaceControlAdministration,
      WorkspaceControl.publication => l10n.workspaceControlPublication,
      WorkspaceControl.archive => l10n.workspaceControlArchive,
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
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final label = workspaceControlLabel(l10n, control);
    return Semantics(
      key: anchor,
      container: true,
      label: label,
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
                  l10n.workspaceControlGoesHere(label),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
          ),
        ),
      ),
    );
  }
}
