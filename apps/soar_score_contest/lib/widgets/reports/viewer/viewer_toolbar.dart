import 'package:flutter/material.dart';

import 'report_sheet_area.dart';

/// The strip above the sheet: page indicator, a one-line legend of what
/// prints, and the zoom controls. A compact window adds the Filters button.
/// Screen only.
class ViewerToolbar extends StatelessWidget {
  const ViewerToolbar({
    super.key,
    required this.pageText,
    required this.legend,
    required this.zoom,
    required this.fit,
    required this.onZoom,
    required this.compact,
    this.onFilters,
    this.filtersLabel,
  });

  final String pageText;
  final String legend;

  /// The fixed zoom, or `null` when fitting the width.
  final double? zoom;

  /// The zoom that fits the width.
  final double fit;
  final ValueChanged<double?> onZoom;
  final bool compact;
  final VoidCallback? onFilters;
  final String? filtersLabel;

  double get _current => zoom ?? fit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final percent = '${(_current * 100).round()}%';
    final zoomIn = reportZoomSteps.cast<double?>().firstWhere(
      (step) => step! > _current + .01,
      orElse: () => 1.5,
    );
    final zoomOut = reportZoomSteps.reversed.cast<double?>().firstWhere(
      (step) => step! < _current - .01,
      orElse: () => .5,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Wrap(
          spacing: 16,
          runSpacing: 0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (compact && onFilters != null)
              TextButton.icon(
                key: const ValueKey('viewer-filters-button'),
                onPressed: onFilters,
                icon: const Icon(Icons.tune, size: 18),
                label: Text(filtersLabel ?? 'Filters'),
              ),
            Semantics(
              liveRegion: true,
              child: Text(
                pageText,
                key: const ValueKey('viewer-page-indicator'),
                style: theme.textTheme.labelLarge,
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  Icon(Icons.print_outlined, size: 16, color: muted),
                  Flexible(
                    child: Text(
                      legend,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              container: true,
              label: 'Zoom',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Zoom out',
                    onPressed: () => onZoom(zoomOut),
                    icon: const Icon(Icons.zoom_out),
                  ),
                  TextButton(
                    key: const ValueKey('viewer-zoom-toggle'),
                    onPressed: () => onZoom(zoom == null ? 1 : null),
                    child: Semantics(
                      label: zoom == null
                          ? 'Zoom: fit width. Switch to 100 percent.'
                          : 'Zoom $percent. Switch to fit width.',
                      excludeSemantics: true,
                      child: Text(
                        zoom == null && !compact ? 'Fit · $percent' : percent,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Zoom in',
                    onPressed: () => onZoom(zoomIn),
                    icon: const Icon(Icons.zoom_in),
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
