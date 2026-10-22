import 'package:flutter/material.dart';

import '../../services/participants/participant_field.dart';
import 'editor_banner.dart';

/// Lists the fields that stopped a save, each one a button that moves focus
/// to the field. Shown above the form after a save attempt.
class ValidationSummary extends StatelessWidget {
  const ValidationSummary({
    required this.problems,
    required this.onGoTo,
    super.key,
  });

  final Map<ParticipantField, String> problems;
  final ValueChanged<ParticipantField> onGoTo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = problems.length;
    return EditorBanner(
      icon: Icons.error,
      title: count == 1
          ? '1 field needs attention'
          : '$count fields need attention',
      body: 'Nothing was saved. Your entries are kept.',
      background: scheme.errorContainer,
      foreground: scheme.onErrorContainer,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 36, top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final MapEntry(key: field, value: message)
                  in problems.entries)
                TextButton(
                  onPressed: () => onGoTo(field),
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.onErrorContainer,
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    '${field.label}: $message',
                    style: const TextStyle(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
