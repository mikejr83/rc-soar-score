import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = controller;
    final pilots = c.scoringPilots;
    final nonFlying = c.nonFlying;
    final count = c.rows.isEmpty
        ? l10n.contestParticipantsCountNone
        : l10n.contestParticipantsCountPilots(
            pilots,
            nonFlying > 0
                ? l10n.contestParticipantsCountNonFlying(nonFlying)
                : '',
          );
    final on = [
      for (final option in ParticipantOption.values)
        if (c.options.contains(option)) _name(l10n, option),
    ];
    final optionLine = on.isEmpty
        ? l10n.contestParticipantsOptionsNone
        : l10n.contestParticipantsOptionsOn(
            _sentence(on),
            on.length == 1 ? 'is' : 'are',
          );
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
              child: Text(l10n.contestParticipantsChangeInConfiguration),
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

  static String _name(AppLocalizations l10n, ParticipantOption option) =>
      switch (option) {
        ParticipantOption.teams => l10n.contestParticipantsOptionTeams,
        ParticipantOption.classes => l10n.contestParticipantsOptionClasses,
        ParticipantOption.roles => l10n.contestParticipantsOptionRoles,
        ParticipantOption.pilotNumbers =>
          l10n.contestParticipantsOptionPilotNumbers,
        ParticipantOption.models => l10n.contestParticipantsOptionPilotModels,
      };
}
