import 'package:material_ui/material_ui.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/workspace/attention/attention_item.dart';
import '../../../services/workspace/attention/needs_attention.dart';
import 'attention_row.dart';

/// The workspace's "what needs a look" card: a row per item, or the empty
/// state. Presentation only; [AttentionSection] reads the facts and decides
/// where a link goes.
class NeedsAttentionCard extends StatelessWidget {
  const NeedsAttentionCard({
    super.key,
    required this.attention,
    required this.onOpen,
    this.onRetry,
  });

  final NeedsAttention attention;

  /// Opens the page that fixes [item].
  final void Function(AttentionItem item) onOpen;

  /// Offered when a source could not be read.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return Card(
      key: const ValueKey('attention-card'),
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 12,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.workspaceAttentionTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    attention.summary,
                    key: const ValueKey('attention-summary'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            for (final item in attention.items)
              AttentionRow(item: item, onOpen: () => onOpen(item)),
            if (attention.isAllClear)
              _note(
                l10n,
                context,
                icon: Icons.check_circle,
                color: AppStatusColors.getSuccess(dark),
                title: NeedsAttention.emptyTitle,
                body: NeedsAttention.emptyText,
              )
            else if (!attention.complete)
              _note(
                l10n,
                context,
                icon: Icons.info_outline,
                color: scheme.onSurfaceVariant,
                title: attention.hasItems
                    ? l10n.workspaceAttentionIncomplete
                    : l10n.workspaceAttentionUnknown,
                body: NeedsAttention.incompleteText,
                retry: onRetry,
              ),
          ],
        ),
      ),
    );
  }

  Widget _note(
    AppLocalizations l10n,
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    VoidCallback? retry,
  }) {
    final theme = Theme.of(context);
    return Padding(
      key: const ValueKey('attention-note'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyLarge),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (retry != null)
                  TextButton(
                    key: const ValueKey('attention-retry'),
                    onPressed: retry,
                    child: Text(l10n.workspaceRetry),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
