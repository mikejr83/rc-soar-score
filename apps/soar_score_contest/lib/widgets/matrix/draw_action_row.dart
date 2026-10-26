import 'package:flutter/material.dart';
import 'package:soar_score_api/soar_score_api.dart';

import '../../l10n/app_localizations.dart';
import '../../services/configuration/draw_readiness.dart';

/// The `Draw matrix` button, always visible, with the reason it is off beside
/// it (icon, one sentence and a link to the fix). While a draw runs the
/// button shows progress and ignores taps, and a progress bar with a Cancel
/// button appears below.
class DrawActionRow extends StatelessWidget {
  const DrawActionRow({
    super.key,
    required this.busy,
    required this.blocker,
    required this.onDraw,
    required this.onFix,
    this.reloadReason,
    this.progress,
    this.cancelling = false,
    this.onCancel,
  });

  final bool busy;
  final DrawBlocker? blocker;
  final VoidCallback onDraw;
  final void Function(BlockerFix fix) onFix;

  /// What the server reported about the running draw, or `null` before its
  /// first report.
  final DrawStatusDto? progress;

  /// Whether Cancel was pressed and the draw has not stopped yet.
  final bool cancelling;

  /// Cancels the running draw.
  final VoidCallback? onCancel;

  /// Shown instead of a blocker after a conflict, until the page reloads.
  final String? reloadReason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final disabled = blocker != null || reloadReason != null;
    final reasonText = reloadReason ?? blocker?.text;
    final l10n = AppLocalizations.of(context);
    final buttons = Wrap(
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
      ],
    );
    if (!busy) {
      return buttons;
    }
    final percent = progress?.percent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        buttons,
        Semantics(
          liveRegion: true,
          child: Text(
            progress == null
                ? l10n.drawProgressStarting
                : l10n.drawProgress(
                    progress!.percent,
                    progress!.seed,
                    progress!.seedCount,
                  ),
            key: const ValueKey('draw-progress-text'),
            style: theme.textTheme.bodyMedium,
          ),
        ),
        LinearProgressIndicator(
          key: const ValueKey('draw-progress-bar'),
          value: percent == null ? null : percent / 100,
        ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton(
              key: const ValueKey('cancel-draw'),
              onPressed: cancelling ? null : onCancel,
              child: Text(
                cancelling ? l10n.drawCancelling : l10n.drawCancelButton,
              ),
            ),
            Text(
              l10n.drawRunningNote,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
