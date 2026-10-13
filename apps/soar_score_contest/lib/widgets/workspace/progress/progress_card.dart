import 'package:flutter/material.dart';

import '../../../services/workspace/progress/progress_headline.dart';
import '../../../services/workspace/progress/progress_summary.dart';
import '../../../services/workspace/progress/progress_text.dart';
import 'progress_tile_view.dart';

/// The workspace's "how far along are we" card: where we are, the lag note,
/// and a wrapping grid of round tiles.
///
/// Presentation only; [ProgressSection] reads the facts and decides what a
/// tile opens.
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.summary,
    required this.zoneId,
    required this.onOpenRound,
    this.onRetry,
  });

  final ProgressSummary summary;

  /// The contest time zone, for the time of the latest score.
  final String zoneId;

  /// Opens Scoring at round [ordinal].
  final void Function(int ordinal) onOpenRound;

  /// Set when the scores could not be read; offers Retry.
  final VoidCallback? onRetry;

  static const double _minTile = 100;
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = summary.headline;
    return Card(
      key: const ValueKey('progress-card'),
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                ProgressText.title,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            switch (headline.stage) {
              ProgressStage.noMatrix => _message(
                context,
                Icons.grid_view,
                ProgressText.emptyTitle,
                ProgressText.emptyBody,
              ),
              ProgressStage.scoresUnavailable => _message(
                context,
                Icons.cloud_off,
                ProgressText.unavailable,
                null,
                retry: onRetry,
              ),
              _ => _data(context),
            },
          ],
        ),
      ),
    );
  }

  Widget _data(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final headline = summary.headline;
    final lag = summary.lag;
    final sub = ProgressText.whereSub(headline, zoneId: zoneId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 24,
          runSpacing: 4,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ProgressText.whereLabel(headline),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  ProgressText.whereMain(headline),
                  key: const ValueKey('progress-where'),
                  style: theme.textTheme.headlineMedium,
                ),
              ],
            ),
            if (sub.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  sub,
                  key: const ValueKey('progress-where-sub'),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        if (lag != null) ...[
          const SizedBox(height: 16),
          DecoratedBox(
            key: const ValueKey('progress-lag'),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ProgressText.lag(lag),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = ((width + _gap) / (_minTile + _gap)).floor().clamp(
              1,
              1000,
            );
            final tileWidth = (width - _gap * (columns - 1)) / columns;
            return Wrap(
              spacing: _gap,
              runSpacing: _gap,
              children: [
                for (final tile in summary.tiles)
                  SizedBox(
                    width: tileWidth,
                    child: ProgressTileView(
                      tile: tile,
                      onOpen: () => onOpenRound(tile.ordinal),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _message(
    BuildContext context,
    IconData icon,
    String title,
    String? body, {
    VoidCallback? retry,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      key: const ValueKey('progress-empty'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: scheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge),
                  if (body != null)
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  if (retry != null)
                    TextButton(
                      key: const ValueKey('progress-retry'),
                      onPressed: retry,
                      child: const Text('Retry'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
