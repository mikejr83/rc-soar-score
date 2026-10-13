import 'package:flutter/material.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../../../services/workspace/progress/progress_text.dart';
import '../../../services/workspace/progress/progress_tile.dart';
import 'dashed_border_painter.dart';

/// One round of the progress card: icon, round, count, state and a bar.
///
/// A tile opens Scoring at its round, except one that is not drawn yet. The
/// state is spelled out in text; the icon and colours only reinforce it.
class ProgressTileView extends StatelessWidget {
  const ProgressTileView({super.key, required this.tile, required this.onOpen});

  final ProgressTile tile;

  /// Opens Scoring at this round.
  final VoidCallback onOpen;

  static const double _radius = 12;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final state = tile.state;
    final warning = AppStatusColors.getWarning(dark);

    final (IconData icon, Color accent) = switch (state) {
      ProgressTileState.scored => (Icons.check_circle, scheme.onSurfaceVariant),
      ProgressTileState.missing => (Icons.warning_amber_rounded, warning),
      ProgressTileState.inProgress => (Icons.timelapse, scheme.primary),
      ProgressTileState.notFlown => (
        Icons.radio_button_unchecked,
        scheme.onSurfaceVariant,
      ),
      ProgressTileState.notDrawn => (Icons.grid_off, scheme.onSurfaceVariant),
    };
    final background = state == ProgressTileState.inProgress
        ? scheme.primaryContainer.withValues(alpha: 0.5)
        : Colors.transparent;
    final borderColor = switch (state) {
      ProgressTileState.missing => warning,
      ProgressTileState.inProgress => scheme.primary,
      _ => scheme.outlineVariant,
    };
    final borderWidth = switch (state) {
      ProgressTileState.missing || ProgressTileState.inProgress => 2.0,
      _ => 1.0,
    };
    final drawn = state != ProgressTileState.notDrawn;

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ProgressText.tileTitle(tile),
                  style: theme.textTheme.labelLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 18, color: accent),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            ProgressText.tileCount(tile),
            style: theme.textTheme.titleMedium,
          ),
          Text(
            ProgressText.tileState(tile),
            style: theme.textTheme.bodySmall?.copyWith(
              color: state == ProgressTileState.missing
                  ? warning
                  : scheme.onSurfaceVariant,
              fontWeight: state == ProgressTileState.missing
                  ? FontWeight.w600
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              minHeight: 4,
              value: tile.total > 0 ? tile.scored / tile.total : 0,
              color: state == ProgressTileState.missing ? warning : accent,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );

    final Widget box = state == ProgressTileState.notDrawn
        ? CustomPaint(
            foregroundPainter: DashedBorderPainter(
              color: scheme.outline,
              radius: _radius,
            ),
            child: content,
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: content,
          );

    return Semantics(
      button: drawn,
      enabled: drawn,
      label: ProgressText.tileLabel(tile),
      excludeSemantics: true,
      onTap: drawn ? onOpen : null,
      child: ConstrainedBox(
        key: ValueKey('progress-tile-${tile.ordinal}'),
        constraints: const BoxConstraints(minHeight: 48),
        child: drawn
            ? InkWell(
                borderRadius: BorderRadius.circular(_radius),
                onTap: onOpen,
                child: box,
              )
            : box,
      ),
    );
  }
}
