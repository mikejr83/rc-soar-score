import 'package:flutter/material.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../../../services/workspace/attention/attention_item.dart';

/// One row of the needs-attention list: a count badge, what it is, the detail
/// and the button that goes where it is fixed.
class AttentionRow extends StatelessWidget {
  const AttentionRow({super.key, required this.item, required this.onOpen});

  final AttentionItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final warning = AppStatusColors.getWarning(dark);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Container(
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${item.count}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onTertiaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(item.title, style: theme.textTheme.bodyLarge),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.detail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: ValueKey('attention-link-${item.kind.name}'),
                    onPressed: onOpen,
                    child: Text(item.linkLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
