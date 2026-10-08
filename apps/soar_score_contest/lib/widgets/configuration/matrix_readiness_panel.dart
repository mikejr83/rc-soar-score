import 'package:flutter/material.dart';

import '../../services/configuration/draw_readiness.dart';
import '../../services/configuration/readiness_summary.dart';
import '../matrix/matrix_colors.dart';

/// Whether the matrix can be drawn, or how the drawn matrix compares with the
/// configuration. It sits under the section list on wide pages and at the end
/// of Draw options on narrow ones.
class MatrixReadinessPanel extends StatelessWidget {
  const MatrixReadinessPanel({
    super.key,
    required this.summary,
    required this.onFix,
    required this.onGoToMatrix,
    this.inline = false,
  });

  final ReadinessSummary summary;
  final void Function(BlockerFix fix) onFix;
  final VoidCallback onGoToMatrix;

  /// Laid out wide, for the end of a section, rather than as a side card.
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = MatrixColors.of(context);
    final iconColor = summary.ok
        ? colors.success
        : summary.icon == Icons.warning_amber
        ? colors.warn
        : scheme.onSurfaceVariant;
    final facts = [
      for (final (label, value) in summary.facts)
        inline
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$label ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
    ];
    return Semantics(
      container: true,
      label: 'Matrix readiness',
      child: Container(
        margin: inline ? const EdgeInsets.only(top: 8, bottom: 20) : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.grid_view, size: 20, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Matrix readiness',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(summary.icon, size: 20, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary.title,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (facts.isNotEmpty) ...[
              const SizedBox(height: 10),
              inline
                  ? Wrap(spacing: 24, runSpacing: 4, children: facts)
                  : Column(
                      children: [
                        for (final fact in facts)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: fact,
                          ),
                      ],
                    ),
            ],
            for (final line in summary.lines) ...[
              const SizedBox(height: 10),
              _line(context, line, colors),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onGoToMatrix,
                icon: const Icon(Icons.grid_view, size: 18),
                label: const Text('Go to matrix'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(BuildContext context, ReadinessLine line, MatrixColors colors) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconColor = switch (line.tone) {
      ReadinessTone.warning => colors.warn,
      ReadinessTone.pending => scheme.primary,
      ReadinessTone.neutral => scheme.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: line.tone == ReadinessTone.pending
            ? null
            : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(line.icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(line.text, style: theme.textTheme.bodySmall),
              ),
            ],
          ),
          if (line.linkLabel != null && line.fix != null)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: TextButton.icon(
                onPressed: () => onFix(line.fix!),
                icon: const Icon(Icons.arrow_forward, size: 16),
                iconAlignment: IconAlignment.end,
                label: Text(line.linkLabel!),
              ),
            ),
        ],
      ),
    );
  }
}
