import 'package:flutter/material.dart';

import '../../services/workspace/workspace_section.dart';

/// The label a section announces to assistive technology and shows on its
/// placeholder.
String workspaceSectionLabel(WorkspaceSection section) => switch (section) {
  WorkspaceSection.nextStep => 'Next step',
  WorkspaceSection.checklist => 'Setup checklist',
  WorkspaceSection.attention => 'Needs attention',
  WorkspaceSection.progress => 'Round progress',
  WorkspaceSection.controls => 'Contest controls',
  WorkspaceSection.facts => 'Contest facts',
  WorkspaceSection.activity => 'Recent activity',
};

/// A labelled region of the workspace page. The widget ticket that owns a
/// section replaces [child]; the layout never changes.
class WorkspaceSectionSlot extends StatelessWidget {
  const WorkspaceSectionSlot({
    super.key,
    required this.section,
    this.readOnly = false,
    this.child,
  });

  final WorkspaceSection section;

  /// True for a completed contest; the widgets inside decide what that hides.
  final bool readOnly;

  /// The section's content; a quiet placeholder card when `null`.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final label = workspaceSectionLabel(section);
    return Semantics(
      container: true,
      label: label,
      child: KeyedSubtree(
        key: ValueKey('workspace-section-${section.id}'),
        child: child ?? WorkspacePlaceholderCard(text: '$label goes here'),
      ),
    );
  }
}

/// The stand-in for a widget that has not landed yet.
class WorkspacePlaceholderCard extends StatelessWidget {
  const WorkspacePlaceholderCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    ),
  );
}
