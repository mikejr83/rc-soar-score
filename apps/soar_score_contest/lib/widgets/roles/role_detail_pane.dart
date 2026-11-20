import 'package:material_ui/material_ui.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../detail_section_card.dart';
import 'role_usage_card.dart';

/// The detail pane of the roles page: the selected role's name, its type and
/// where it is used.
///
/// A role of the director has Rename and Delete; Delete is off while a
/// contest uses the role. A system role has neither action and says why
/// (the Pilot role gets its own explanation). [onBack] shows a back arrow
/// when only the detail is visible.
class RoleDetailPane extends StatelessWidget {
  const RoleDetailPane({
    super.key,
    required this.role,
    required this.usage,
    required this.onRetryUsage,
    required this.onRename,
    required this.onDelete,
    this.onBack,
  });

  final Role role;
  final Future<List<RoleUsage>> usage;
  final VoidCallback onRetryUsage;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback? onBack;

  /// Why the system roles cannot be changed.
  static String pilotExplanation(AppLocalizations l10n) =>
      l10n.rolesPilotExplanation;
  static String systemExplanation(AppLocalizations l10n) =>
      l10n.rolesSystemExplanation;

  static String inUseExplanation(AppLocalizations l10n) =>
      l10n.rolesInUseExplanation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      children: [
        Row(
          children: [
            if (onBack != null)
              IconButton(
                key: const ValueKey('role-detail-back'),
                tooltip: l10n.rolesBackToRoles,
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
            const Icon(Icons.badge_outlined, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                role.displayName,
                style: theme.textTheme.headlineSmall,
              ),
            ),
            if (!role.isSystem) ...[
              FilledButton.tonalIcon(
                key: const ValueKey('rename-role'),
                onPressed: onRename,
                icon: const Icon(Icons.edit, size: 18),
                label: Text(l10n.rolesRenameButton),
              ),
              FutureBuilder<List<RoleUsage>>(
                future: usage,
                builder: (context, snapshot) {
                  // Locked until the usage is known and found empty.
                  final deletable = snapshot.data?.isEmpty ?? false;
                  return IconButton(
                    key: const ValueKey('delete-role'),
                    tooltip: deletable
                        ? l10n.rolesDeleteTooltip(role.displayName)
                        : l10n.rolesInUseTooltip,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: deletable ? onDelete : null,
                  );
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        if (role.isSystem)
          _Note(
            key: const ValueKey('system-role-note'),
            icon: Icons.lock_outline,
            text: role.id == SystemRoles.pilotId
                ? pilotExplanation(l10n)
                : systemExplanation(l10n),
          ),
        if (role.isSystem) const SizedBox(height: 24),
        DetailSectionCard(
          title: l10n.rolesType,
          items: [
            DetailItem(
              l10n.rolesType,
              role.type == RoleType.pilot
                  ? l10n.rolesPilot
                  : l10n.rolesNonFlier,
            ),
            DetailItem(
              l10n.rolesOwner,
              role.isSystem ? l10n.rolesOwnerSystem : l10n.rolesOwnerYou,
            ),
            DetailItem(
              l10n.rolesScores,
              role.type == RoleType.pilot
                  ? l10n.rolesReceivesScores
                  : l10n.rolesNoScores,
            ),
          ],
        ),
        const SizedBox(height: 24),
        RoleUsageCard(usage: usage, onRetry: onRetryUsage),
        if (!role.isSystem)
          FutureBuilder<List<RoleUsage>>(
            future: usage,
            builder: (context, snapshot) => (snapshot.data?.isNotEmpty ?? false)
                ? Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: _Note(
                      key: const ValueKey('in-use-note'),
                      icon: Icons.info_outline,
                      text: inUseExplanation(l10n),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
