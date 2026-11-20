import 'package:material_ui/material_ui.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../../services/configuration/section_id.dart';

/// The Scoring access and Administration lock sections: the current value in
/// words and the way to change it. Both are contest controls that act at once
/// from the Workspace, not settings saved with the configuration.
class ContestStateSectionBody extends StatelessWidget {
  const ContestStateSectionBody({
    super.key,
    required this.id,
    required this.contest,
    required this.onOpenWorkspace,
  }) : assert(id == SectionId.scoringAccess || id == SectionId.adminLock);

  final SectionId id;
  final Contest contest;
  final VoidCallback onOpenWorkspace;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (icon, value, detail) = switch (id) {
      SectionId.scoringAccess
          when contest.scoringAccess == ScoringAccess.open =>
        (
          Icons.lock_open,
          l10n.shellScoringOpen,
          l10n.configStateScoringOpenDetail,
        ),
      SectionId.scoringAccess => (
        Icons.block,
        l10n.shellScoringClosed,
        l10n.configStateScoringClosedDetail,
      ),
      _ when contest.adminLock == AdminLock.locked => (
        Icons.lock_outline,
        l10n.shellAdminLocked,
        l10n.configStateAdminLockedDetail,
      ),
      _ => (
        Icons.lock_open,
        l10n.shellAdminUnlocked,
        l10n.configStateAdminUnlockedDetail,
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Icon(icon, size: 20, color: scheme.onSurfaceVariant),
              Text(
                value,
                key: ValueKey('state-${id.name}'),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          Text(
            detail,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          OutlinedButton.icon(
            onPressed: onOpenWorkspace,
            icon: const Icon(Icons.dashboard_outlined, size: 18),
            label: Text(l10n.configChangeInWorkspace),
          ),
        ],
      ),
    );
  }
}
