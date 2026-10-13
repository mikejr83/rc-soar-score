import 'package:flutter/material.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../../../services/workspace/checklist/checklist_item.dart';

/// One checklist row: an icon, the title and one line of detail, the status
/// as text, and a chevron. The whole row is the button.
class ChecklistRow extends StatelessWidget {
  const ChecklistRow({super.key, required this.item, required this.onPressed});

  final ChecklistItem item;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _StatusStyle.of(theme, item.status);
    return Semantics(
      button: true,
      container: true,
      excludeSemantics: true,
      label: item.semanticLabel,
      onTap: onPressed,
      child: InkWell(
        key: ValueKey('checklist-row-${item.id.name}'),
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(style.icon, color: style.color, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        item.detail,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  item.status.label,
                  key: ValueKey('checklist-status-${item.id.name}'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: style.color,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The icon and colour of a status. The colour is never the only signal: the
/// row also shows the status word.
class _StatusStyle {
  const _StatusStyle(this.icon, this.color);

  factory _StatusStyle.of(ThemeData theme, ChecklistStatus status) {
    final dark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;
    return switch (status) {
      ChecklistStatus.done => _StatusStyle(
        Icons.check_circle,
        AppStatusColors.getSuccess(dark),
      ),
      ChecklistStatus.todo => _StatusStyle(
        Icons.radio_button_unchecked,
        scheme.onSurfaceVariant,
      ),
      ChecklistStatus.missing => _StatusStyle(Icons.error, scheme.error),
      ChecklistStatus.check => _StatusStyle(
        Icons.warning_amber,
        AppStatusColors.getWarning(dark),
      ),
      ChecklistStatus.unknown => _StatusStyle(
        Icons.help_outline,
        scheme.onSurfaceVariant,
      ),
    };
  }

  final IconData icon;
  final Color color;
}
