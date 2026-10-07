import 'package:flutter/material.dart';
import 'package:soar_score_core/services/role_usage.dart';
import 'package:soar_score_core/soar_score_core.dart';

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
  static const String pilotExplanation =
      'The Pilot role is fixed. Every participant starts as a pilot, and '
      'only pilots fly and receive scores, so it cannot be renamed or '
      'deleted.';
  static const String systemExplanation =
      'This is a system role shared by every director, so it cannot be '
      'renamed or deleted.';

  static const String inUseExplanation =
      'A role that participants have cannot be deleted. Change those '
      'participants to another role first.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      children: [
        Row(
          children: [
            if (onBack != null)
              IconButton(
                key: const ValueKey('role-detail-back'),
                tooltip: 'Back to roles',
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
                label: const Text('Rename'),
              ),
              FutureBuilder<List<RoleUsage>>(
                future: usage,
                builder: (context, snapshot) {
                  // Locked until the usage is known and found empty.
                  final deletable = snapshot.data?.isEmpty ?? false;
                  return IconButton(
                    key: const ValueKey('delete-role'),
                    tooltip: deletable
                        ? 'Delete ${role.displayName}'
                        : 'In use, cannot delete',
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
                ? pilotExplanation
                : systemExplanation,
          ),
        if (role.isSystem) const SizedBox(height: 24),
        DetailSectionCard(
          title: 'Role',
          items: [
            DetailItem(
              'Type',
              role.type == RoleType.pilot ? 'Pilot' : 'Non-flier',
            ),
            DetailItem('Owner', role.isSystem ? 'System' : 'You'),
            DetailItem(
              'Scores',
              role.type == RoleType.pilot ? 'Receives scores' : 'No scores',
            ),
          ],
        ),
        const SizedBox(height: 24),
        RoleUsageCard(usage: usage, onRetry: onRetryUsage),
        if (!role.isSystem)
          FutureBuilder<List<RoleUsage>>(
            future: usage,
            builder: (context, snapshot) => (snapshot.data?.isNotEmpty ?? false)
                ? const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: _Note(
                      key: ValueKey('in-use-note'),
                      icon: Icons.info_outline,
                      text: inUseExplanation,
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
