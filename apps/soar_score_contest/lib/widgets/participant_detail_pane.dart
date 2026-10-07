import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'detail_section_card.dart';
import 'participant_list_pane.dart';

/// The detail pane of the participant page: the selected participant's
/// avatar, name and club, the Edit and Delete actions, and their data in
/// section cards. [onBack] shows a back arrow when only the detail is
/// visible.
class ParticipantDetailPane extends StatelessWidget {
  const ParticipantDetailPane({
    super.key,
    required this.profile,
    required this.onEdit,
    required this.onDelete,
    this.onBack,
  });

  final ParticipantProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = '${profile.firstName} ${profile.lastName}';
    final club = profile.club;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      children: [
        Row(
          children: [
            if (onBack != null)
              IconButton(
                key: const ValueKey('participant-detail-back'),
                tooltip: 'Back to participants',
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
            ParticipantAvatar(profile: profile, radius: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.headlineSmall),
                  if (club != null && club.isNotEmpty)
                    Text(
                      club,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              key: const ValueKey('edit-participant'),
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit'),
            ),
            IconButton(
              tooltip: 'Delete $name',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
        const SizedBox(height: 24),
        DetailSectionCard(
          title: 'Identification',
          items: [
            DetailItem('FAI number', profile.faiNumber),
            DetailItem('National organization ID', profile.nationalOrgId),
            DetailItem('Club', profile.club),
          ],
        ),
        const SizedBox(height: 24),
        DetailSectionCard(
          title: 'Location',
          items: [
            DetailItem('City', profile.city),
            DetailItem('State/province', profile.state),
            DetailItem('Country', profile.country),
          ],
        ),
        const SizedBox(height: 24),
        DetailSectionCard(
          title: 'Contact',
          items: [
            DetailItem(
              'Email (private, used for matching only)',
              profile.email,
            ),
          ],
        ),
      ],
    );
  }
}
