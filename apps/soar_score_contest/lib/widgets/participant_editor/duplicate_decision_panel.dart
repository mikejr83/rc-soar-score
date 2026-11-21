import 'package:material_ui/material_ui.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../l10n/app_localizations.dart';
import '../../services/participants/participant_field.dart';
import '../../services/participants/participant_field_rules.dart';
import '../../services/participants/participant_form_values.dart';

/// Shown in place of the form's notices when Save finds a profile with the
/// same email: the existing profile beside what was typed, and two choices.
/// A decision, not an error; nothing is saved until one is made.
class DuplicateDecisionPanel extends StatelessWidget {
  const DuplicateDecisionPanel({
    required this.existing,
    required this.entered,
    required this.addsToContest,
    required this.onUseExisting,
    required this.onBackToEdit,
    this.focusNode,
    super.key,
  });

  final ParticipantProfile existing;
  final ParticipantFormValues entered;

  /// True when the editor was opened from the New Contest wizard, where
  /// using the existing profile adds it to the contest.
  final bool addsToContest;
  final VoidCallback onUseExisting;
  final VoidCallback onBackToEdit;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final words = AppLocalizations.of(context);
    final existingName = '${existing.firstName} ${existing.lastName}';
    final enteredName = entered.fullName;
    return Focus(
      focusNode: focusNode,
      child: Semantics(
        liveRegion: true,
        container: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: scheme.onSecondaryContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: scheme.surface,
                        foregroundColor: scheme.primary,
                        child: const Icon(Icons.person_search),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              words.participantEditorDuplicateLead,
                              style: theme.textTheme.labelMedium,
                            ),
                            Text(
                              words.participantEditorDuplicateTitle,
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(
                              words.participantEditorDuplicateCompare,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _tile(
                        context,
                        words.participantEditorDuplicateExisting,
                        existingName,
                        existing.club,
                        _place(existing.city, existing.state),
                        maskEmail(existing.email ?? ''),
                        filled: true,
                      ),
                      _tile(
                        context,
                        words.participantEditorDuplicateEntered,
                        enteredName,
                        entered.optional(ParticipantField.club),
                        _place(
                          entered.optional(ParticipantField.city),
                          entered.optional(ParticipantField.state),
                        ),
                        maskEmail(entered[ParticipantField.email].trim()),
                        filled: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const ValueKey('use-existing'),
                    onPressed: onUseExisting,
                    child: Text(words.participantEditorUseExisting),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 12),
                    child: Text(
                      addsToContest
                          ? words.participantEditorDuplicateAdds(existingName)
                          : words.participantEditorDuplicateOpens(existingName),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  OutlinedButton(
                    key: const ValueKey('change-email'),
                    onPressed: onBackToEdit,
                    child: Text(words.participantEditorChangeEmail),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      words.participantEditorDuplicateNote(
                        enteredName.isEmpty
                            ? words.participantEditorThisPerson
                            : enteredName,
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String? _place(String? city, String? state) {
    final parts = [?city, ?state].where((p) => p.trim().isNotEmpty);
    return parts.isEmpty ? null : parts.join(', ');
  }

  Widget _tile(
    BuildContext context,
    String heading,
    String name,
    String? club,
    String? place,
    String maskedEmail, {
    required bool filled,
  }) {
    final theme = Theme.of(context);
    final words = AppLocalizations.of(context);
    final scheme = theme.colorScheme;
    final initials = name.isEmpty
        ? '?'
        : name.split(' ').map((p) => p[0]).take(2).join().toUpperCase();
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: filled ? scheme.surfaceContainerLow : null,
          border: filled ? null : Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: scheme.onSurface),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      foregroundColor: scheme.onPrimaryContainer,
                      child: Text(initials),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? words.participantEditorNoName : name,
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            club ?? words.participantEditorNoClub,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            place ?? words.participantEditorNoLocation,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Semantics(
                      label: words.participantEditorEmailPrefix(maskedEmail[0]),
                      excludeSemantics: true,
                      child: Text(
                        maskedEmail,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
