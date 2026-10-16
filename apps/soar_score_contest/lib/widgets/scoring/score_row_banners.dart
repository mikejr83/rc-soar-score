import 'package:flutter/material.dart';

import '../../services/scoring/row_save.dart';
import '../matrix/matrix_colors.dart';

/// A line of text with an icon, and an optional button, under the entry
/// fields. A question or a message, never a modal.
class ScoreInlineNote extends StatelessWidget {
  const ScoreInlineNote({
    super.key,
    required this.icon,
    required this.text,
    this.color,
    this.actionLabel,
    this.onAction,
    this.actionKey,
  });

  final IconData icon;
  final String text;
  final Color? color;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(icon, size: 20, color: tint),
            Text(text, style: theme.textTheme.bodyMedium),
            if (actionLabel != null)
              TextButton(
                key: actionKey,
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}

/// What a failed or conflicting save says, and what can be done. The typed
/// values are always kept.
class ScoreSaveBanner extends StatelessWidget {
  const ScoreSaveBanner({
    super.key,
    required this.save,
    required this.mine,
    required this.theirs,
    required this.onRetry,
    required this.onRefresh,
    required this.onKeepMine,
    required this.onTakeTheirs,
  });

  final RowSave save;
  final Map<String, Object?> mine;
  final Map<String, Object?>? theirs;
  final VoidCallback onRetry;
  final VoidCallback onRefresh;
  final VoidCallback onKeepMine;
  final VoidCallback onTakeTheirs;

  static String _summary(Map<String, Object?>? c) {
    if (c == null || c.isEmpty) return 'nothing entered';
    return c.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    final warn = MatrixColors.of(context).warn;
    switch (save.kind) {
      case RowSaveKind.stale:
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            key: const ValueKey('score-stale'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: warn, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sync_problem, color: warn),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This row changed since you opened it. Yours: '
                        '${_summary(mine)}. Newer: ${_summary(theirs)}.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(
                      key: const ValueKey('score-keep-mine'),
                      onPressed: onKeepMine,
                      child: const Text('Keep mine'),
                    ),
                    OutlinedButton(
                      key: const ValueKey('score-take-theirs'),
                      onPressed: onTakeTheirs,
                      child: const Text('Take the newer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      case RowSaveKind.failed:
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            key: const ValueKey('score-save-failed'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: error, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(Icons.error_outline, color: error),
                Text('Not saved. ${save.message ?? ''} Your values are kept.'),
                if (save.networkProblem)
                  FilledButton(
                    key: const ValueKey('score-retry'),
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  )
                else
                  OutlinedButton(
                    key: const ValueKey('score-refresh'),
                    onPressed: onRefresh,
                    child: const Text('Refresh'),
                  ),
              ],
            ),
          ),
        );
      case RowSaveKind.refused:
        return ScoreInlineNote(
          icon: Icons.error_outline,
          color: error,
          text:
              'Refused: ${save.message ?? 'the entry was not accepted'}. '
              'Your values are kept.',
          actionLabel: 'Refresh',
          onAction: onRefresh,
        );
      case RowSaveKind.idle:
      case RowSaveKind.saving:
        return const SizedBox.shrink();
    }
  }
}
