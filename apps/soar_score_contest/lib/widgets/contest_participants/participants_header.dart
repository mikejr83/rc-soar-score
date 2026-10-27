import 'package:flutter/material.dart';

import '../../services/contest_participants/participants_controller.dart';
import '../../services/participants/participant_option.dart';

/// The count line ("12 pilots, 2 non-flying") and which participant options
/// are on, linking to Configuration where they change.
class ParticipantsHeader extends StatelessWidget {
  const ParticipantsHeader({
    super.key,
    required this.controller,
    required this.onOpenConfiguration,
  });

  final ParticipantsController controller;
  final VoidCallback onOpenConfiguration;

  static const _names = {
    ParticipantOption.teams: 'teams',
    ParticipantOption.classes: 'classes',
    ParticipantOption.roles: 'roles',
    ParticipantOption.pilotNumbers: 'pilot numbers',
    ParticipantOption.models: 'pilot models',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = controller;
    final pilots = c.scoringPilots;
    final nonFlying = c.nonFlying;
    final count = c.rows.isEmpty
        ? 'No participants'
        : '$pilots pilot${pilots == 1 ? '' : 's'}'
              '${nonFlying > 0 ? ', $nonFlying non-flying' : ''}';
    final on = [
      for (final option in ParticipantOption.values)
        if (c.options.contains(option)) _names[option]!,
    ];
    final optionLine = on.isEmpty
        ? 'No participant options are on.'
        : '${_sentence(on)} ${on.length == 1 ? 'is' : 'are'} on.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count,
          key: const ValueKey('participants-count'),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              optionLine,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            TextButton(
              key: const ValueKey('participants-open-configuration'),
              onPressed: onOpenConfiguration,
              child: const Text('Change in Configuration.'),
            ),
          ],
        ),
      ],
    );
  }

  /// `teams, classes` → `Teams and classes`.
  static String _sentence(List<String> items) {
    final text = items.length < 2
        ? items.join()
        : '${items.sublist(0, items.length - 1).join(', ')} and '
              '${items.last}';
    return text[0].toUpperCase() + text.substring(1);
  }
}
