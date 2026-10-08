import 'package:flutter/material.dart';

import '../../services/configuration/configuration_draft.dart';
import '../../services/configuration/readiness_summary.dart';

/// Asks before saving a change that has an impact: it makes the drawn matrix
/// out of date, or recalculates results. Closes with `true` to save.
class SaveConfirmDialog extends StatelessWidget {
  const SaveConfirmDialog({
    super.key,
    required this.draft,
    this.matrixRevision,
  });

  final ConfigurationDraft draft;

  /// The drawn matrix's revision, for the sentence about it.
  final int? matrixRevision;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final matrix = draft.matrixChanges;
    final recalc = draft.recalcChanges;
    final other = draft.otherChanges;
    String names(List<SettingChange> changes) =>
        ReadinessSummary.lowerList([for (final c in changes) c.def.label]);

    Widget item(IconData icon, String head, String text, Color bg, Color fg) =>
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: fg),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      head,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      text,
                      style: theme.textTheme.bodyMedium?.copyWith(color: fg),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    return AlertDialog(
      icon: const Icon(Icons.save_outlined),
      title: const Text('Save configuration?'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (matrix.isNotEmpty)
            item(
              Icons.sync_problem,
              'The drawn matrix becomes out of date',
              '${names(matrix)} changed. The drawn matrix'
                  '${matrixRevision == null ? '' : ' (revision $matrixRevision)'} '
                  'no longer matches; redraw unscored rounds on the Matrix '
                  'page.',
              scheme.tertiaryContainer,
              scheme.onTertiaryContainer,
            ),
          if (recalc.isNotEmpty) ...[
            if (matrix.isNotEmpty) const SizedBox(height: 12),
            item(
              Icons.calculate_outlined,
              'Results are recalculated',
              '${names(recalc)} changed. All results will be recalculated.',
              scheme.primaryContainer,
              scheme.onPrimaryContainer,
            ),
          ],
          if (other.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check, size: 20, color: scheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Also saving, with no effect on the matrix or results: '
                    '${names(other)}.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('confirm-save'),
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Save configuration'),
        ),
      ],
    );
  }
}
