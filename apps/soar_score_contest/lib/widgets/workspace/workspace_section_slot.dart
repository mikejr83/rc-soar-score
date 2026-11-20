import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../services/workspace/workspace_section.dart';

/// The label a section announces to assistive technology and shows on its
/// placeholder.
String workspaceSectionLabel(
  AppLocalizations l10n,
  WorkspaceSection section,
) => switch (section) {
  WorkspaceSection.nextStep => l10n.workspaceSectionNextStep,
  WorkspaceSection.checklist => l10n.workspaceSectionChecklist,
  WorkspaceSection.invitations => l10n.workspaceSectionInvitations,
  WorkspaceSection.attention => l10n.workspaceSectionAttention,
  WorkspaceSection.progress => l10n.workspaceSectionProgress,
  WorkspaceSection.controls => l10n.workspaceSectionControls,
  WorkspaceSection.facts => l10n.workspaceSectionFacts,
  WorkspaceSection.activity => l10n.workspaceSectionActivity,
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
    final l10n = AppLocalizations.of(context);
    final label = workspaceSectionLabel(l10n, section);
    return Semantics(
      container: true,
      label: label,
      child: KeyedSubtree(
        key: ValueKey('workspace-section-${section.id}'),
        child:
            child ??
            WorkspacePlaceholderCard(text: l10n.workspaceSectionGoesHere(label)),
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
