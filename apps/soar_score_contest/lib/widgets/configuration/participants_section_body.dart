import 'package:flutter/material.dart';

import '../../services/configuration/configuration_data.dart';
import '../../services/configuration/configuration_draft.dart';
import '../../services/configuration/setting_keys.dart';

/// The Participants section: counts of who is entered and the way to edit
/// them. Participants are edited on their own page.
class ParticipantsSectionBody extends StatelessWidget {
  const ParticipantsSectionBody({
    super.key,
    required this.data,
    required this.draft,
    required this.onOpenParticipants,
  });

  final ConfigurationData data;
  final ConfigurationDraft? draft;
  final VoidCallback onOpenParticipants;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pilots = data.scoringPilots;
    final counts = [
      ('Scoring pilots', pilots),
      ('Other participants', data.participations.length - pilots),
      if (draft?[SettingKeys.teams] == true) ('Teams', data.teamCount),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: scheme.outlineVariant),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final (label, value) in counts)
                Container(
                  width: 160,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border.all(color: scheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$value',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (pilots < 2) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 20,
                    color: scheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A matrix needs at least 2 scoring pilots. This contest '
                      'has $pilots.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onOpenParticipants,
                icon: const Icon(Icons.groups_outlined, size: 18),
                label: const Text('Open Participants'),
              ),
              Text(
                'Participants are edited there.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
