import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
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
    final words = AppLocalizations.of(context);
    return Card(
      key: const ValueKey('review-differences'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              words.participantEditorReviewTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              words.participantEditorReviewBody,
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
                  child: Text(words.participantEditorReviewReload),
                ),
                FilledButton(
                  key: const ValueKey('review-apply'),
                  onPressed: onApply,
                  child: Text(words.participantEditorReviewApply),
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
                AppLocalizations.of(context).participantEditorReviewYourVersion,
                difference.mine,
              ),
              _choice(
                context,
                difference,
                ReviewChoice.theirs,
                AppLocalizations.of(context)
                    .participantEditorReviewTheirVersion,
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
    final words = AppLocalizations.of(context);
    final selected = difference.choice == choice;
    final scheme = theme.colorScheme;
    final blank = words.participantEditorReviewBlank;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        label: '$heading: ${value.isEmpty ? blank : value}',
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
                        value.isEmpty ? blank : value,
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
