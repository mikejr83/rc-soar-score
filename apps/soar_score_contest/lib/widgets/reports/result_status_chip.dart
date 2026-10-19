import 'package:flutter/material.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../../services/reports/result_status.dart';

/// A result status as a bordered chip with an icon and its word, so it never
/// relies on colour.
class ResultStatusChip extends StatelessWidget {
  const ResultStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  final ResultStatus status;

  /// A smaller chip for the help popover's list.
  final bool compact;

  static IconData icon(ResultStatus status) => switch (status) {
    ResultStatus.official => Icons.verified,
    ResultStatus.preliminary => Icons.pending,
    ResultStatus.none => Icons.remove,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (background, foreground, border) = switch (status) {
      ResultStatus.official => (
        AppStatusColors.getSuccessContainer(dark),
        AppStatusColors.getOnSuccessContainer(dark),
        Colors.transparent,
      ),
      ResultStatus.preliminary => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        AppStatusColors.getWarning(dark),
      ),
      ResultStatus.none => (
        Colors.transparent,
        scheme.onSurfaceVariant,
        scheme.outline,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon(status), size: compact ? 16 : 18, color: foreground),
            const SizedBox(width: 4),
            Text(
              status.label,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: foreground, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
