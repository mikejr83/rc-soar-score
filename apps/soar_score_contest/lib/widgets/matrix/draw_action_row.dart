import 'package:flutter/material.dart';

import '../../services/configuration/draw_readiness.dart';

/// The `Draw matrix` button, always visible, with the reason it is off beside
/// it (icon, one sentence and a link to the fix). While a draw runs the
/// button shows progress and ignores taps.
class DrawActionRow extends StatelessWidget {
  const DrawActionRow({
    super.key,
    required this.busy,
    required this.blocker,
    required this.onDraw,
    required this.onFix,
    this.reloadReason,
  });

  final bool busy;
  final DrawBlocker? blocker;
  final VoidCallback onDraw;
  final void Function(BlockerFix fix) onFix;

  /// Shown instead of a blocker after a conflict, until the page reloads.
  final String? reloadReason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final disabled = blocker != null || reloadReason != null;
    final reasonText = reloadReason ?? blocker?.text;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.icon(
          key: const ValueKey('draw-button'),
          onPressed: disabled || busy ? null : onDraw,
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.grid_view, size: 18),
          label: Text(busy ? 'Drawing matrix…' : 'Draw matrix'),
        ),
        if (reasonText != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Semantics(
              container: true,
              liveRegion: true,
              child: DecoratedBox(
                key: const ValueKey('draw-reason'),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                  child: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(
                        reloadReason != null
                            ? Icons.sync_problem
                            : blocker!.icon,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Text(reasonText),
                      ),
                      if (reloadReason == null && blocker!.fix != null)
                        TextButton.icon(
                          onPressed: () => onFix(blocker!.fix!),
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: Text(blocker!.linkLabel ?? 'Open'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (busy)
          Text(
            'The server is drawing the matrix. Keep this page open.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
