import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

/// The master pane of the roles page: title and count, and every role. The
/// system roles carry a lock; the row for [selectedId] is highlighted when
/// [highlight] is set.
class RoleListPane extends StatelessWidget {
  const RoleListPane({
    super.key,
    required this.roles,
    required this.selectedId,
    required this.highlight,
    required this.onSelect,
  });

  /// Every role, already sorted.
  final List<Role> roles;
  final Id? selectedId;
  final bool highlight;
  final ValueChanged<Role> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Roles', style: theme.textTheme.titleLarge),
              const SizedBox(width: 12),
              Text(
                '${roles.length} roles',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: roles.length,
            itemBuilder: (context, index) {
              final role = roles[index];
              return ListTile(
                key: ValueKey('role-${role.id.value}'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                selected: highlight && role.id == selectedId,
                selectedTileColor: theme.colorScheme.secondaryContainer,
                leading: const Icon(Icons.badge_outlined),
                title: Text(role.displayName),
                subtitle: Text(role.isSystem ? 'System role' : 'Your role'),
                trailing: role.isSystem
                    ? const Icon(Icons.lock_outline, size: 18)
                    : null,
                onTap: () => onSelect(role),
              );
            },
          ),
        ),
      ],
    );
  }
}
