import 'package:flutter/material.dart';

import '../../services/participants/participant_field.dart';
import '../../services/participants/participant_review.dart';

/// Lets the director choose, for each field that differs, their own value or
/// the one saved elsewhere, then save the result.
class ReviewDifferencesPanel extends StatelessWidget {
  const ReviewDifferencesPanel({
    required this.review,
    required this.onChoose,
    required this.onReloadTheirs,
    required this.onApply,
    super.key,
  });

  final ParticipantReview review;
  final void Function(ParticipantField field, ReviewChoice choice) onChoose;
  final VoidCallback onReloadTheirs;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('review-differences'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Review differences', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Choose the value to keep for each field that differs. Fields '
              'you changed start on your version; fields only they changed '
              'start on theirs.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            for (final difference in review.differences)
              _row(context, difference),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  key: const ValueKey('review-reload'),
                  onPressed: onReloadTheirs,
                  child: const Text('Reload their version'),
                ),
                FilledButton(
                  key: const ValueKey('review-apply'),
                  onPressed: onApply,
                  child: const Text('Save with these choices'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, FieldDifference difference) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Semantics(
      container: true,
      label: difference.field.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            difference.field.label,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _choice(
                context,
                difference,
                ReviewChoice.mine,
                'Your version',
                difference.mine,
              ),
              _choice(
                context,
                difference,
                ReviewChoice.theirs,
                'Their version',
                difference.theirs,
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _choice(
    BuildContext context,
    FieldDifference difference,
    ReviewChoice choice,
    String heading,
    String value,
  ) {
    final theme = Theme.of(context);
    final selected = difference.choice == choice;
    final scheme = theme.colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        label: '$heading: ${value.isEmpty ? '(blank)' : value}',
        excludeSemantics: true,
        child: InkWell(
          key: ValueKey('review-${difference.field.name}-${choice.name}'),
          borderRadius: BorderRadius.circular(8),
          onTap: () => onChoose(difference.field, choice),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        heading,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        value.isEmpty ? '(blank)' : value,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
