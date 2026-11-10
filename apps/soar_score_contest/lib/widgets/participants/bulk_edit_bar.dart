import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/participants/participant_row.dart';
import 'team_avatar.dart';

/// The toolbar shown while rows are selected: set team, class or role for
/// all of them at once, remove them, or clear the selection.
class BulkEditBar extends StatelessWidget {
  const BulkEditBar({
    super.key,
    required this.count,
    required this.onClear,
    required this.onRemove,
    this.removeReason,
    this.showRemove = true,
    this.actions = const [],
    this.teams,
    this.classes,
    this.roles,
    this.onTeam,
    this.onClass,
    this.onRole,
  });

  /// Additional actions for the current selection, styled like bulk actions.
  final List<Widget> actions;

  /// Read-only lists can retain selection actions without offering removal.
  final bool showRemove;

  final int count;
  final VoidCallback onClear;

  /// Removes the selected rows; `null` turns the button off.
  final VoidCallback? onRemove;

  /// Why Remove is off, as its tooltip.
  final String? removeReason;

  /// The choices for each bulk action; `null` hides the action (its option
  /// is off).
  final List<TeamSummary>? teams;
  final List<String>? classes;
  final List<Role>? roles;

  final ValueChanged<String>? onTeam;
  final ValueChanged<String>? onClass;
  final ValueChanged<Role>? onRole;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = scheme.onSecondaryContainer;
    final buttonStyle = TextButton.styleFrom(foregroundColor: foreground);

    Widget menu<T>({
      required Key key,
      required String label,
      required IconData icon,
      required String title,
      required List<T> items,
      required Widget Function(T item) leading,
      required String Function(T item) text,
      required ValueChanged<T> onPick,
    }) => MenuAnchor(
      menuChildren: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        if (items.isEmpty)
          const MenuItemButton(child: Text('Nothing entered yet')),
        for (final item in items)
          MenuItemButton(
            leadingIcon: leading(item),
            onPressed: () => onPick(item),
            child: Text(text(item)),
          ),
      ],
      builder: (context, controller, child) => TextButton.icon(
        key: key,
        style: buttonStyle,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );

    return Semantics(
      container: true,
      label: 'Bulk edit selected participants',
      child: Container(
        key: const ValueKey('bulk-edit-bar'),
        padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          spacing: 4,
          runSpacing: 4,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '$count selected',
                style: theme.textTheme.labelLarge?.copyWith(color: foreground),
              ),
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                if (teams != null && onTeam != null)
                  menu<TeamSummary>(
                    key: const ValueKey('bulk-team'),
                    label: 'Set team',
                    icon: Icons.diversity_3,
                    title: 'Set team for $count',
                    items: teams!,
                    leading: (team) => TeamAvatar(team: team.name),
                    text: (team) => team.name,
                    onPick: (team) => onTeam!(team.name),
                  ),
                if (classes != null && onClass != null)
                  menu<String>(
                    key: const ValueKey('bulk-class'),
                    label: 'Set class',
                    icon: Icons.workspace_premium_outlined,
                    title: 'Set class for $count',
                    items: classes!,
                    leading: (value) => CircleAvatar(
                      radius: 14,
                      child: Text(initials(value).substring(0, 1)),
                    ),
                    text: (value) => value,
                    onPick: onClass!,
                  ),
                if (roles != null && onRole != null)
                  menu<Role>(
                    key: const ValueKey('bulk-role'),
                    label: 'Set role',
                    icon: Icons.badge_outlined,
                    title: 'Set role for $count',
                    items: roles!,
                    leading: (role) => const Icon(Icons.badge_outlined),
                    text: (role) => role.displayName,
                    onPick: onRole!,
                  ),
                ...actions,
                if (showRemove)
                  Tooltip(
                    message: removeReason ?? '',
                    child: TextButton.icon(
                      key: const ValueKey('bulk-remove'),
                      style: buttonStyle,
                      onPressed: onRemove,
                      icon: const Icon(Icons.person_remove_outlined, size: 18),
                      label: const Text('Remove'),
                    ),
                  ),
                IconButton(
                  tooltip: 'Clear selection',
                  color: foreground,
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
