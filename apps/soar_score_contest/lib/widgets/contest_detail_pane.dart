import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'contest_list.dart';
import 'contest_status_chip.dart';
import 'detail_section_card.dart';

/// The detail pane of the contests page: the selected contest's name,
/// status and `Open contest` action, and its data in section cards.
/// [onBack] shows a back arrow when only the detail is visible.
class ContestDetailPane extends StatelessWidget {
  const ContestDetailPane({
    super.key,
    required this.contest,
    required this.onOpen,
    this.onBack,
  });

  final Contest contest;
  final VoidCallback onOpen;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = [
      contest.city,
      contest.state,
      contest.country,
    ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onBack != null)
              IconButton(
                key: const ValueKey('contest-detail-back'),
                tooltip: 'Back to contests',
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contest.name, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  ContestStatusChip(state: contest.lifecycleState),
                ],
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              key: const ValueKey('open-contest'),
              onPressed: onOpen,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Open contest'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        DetailSectionCard(
          title: 'Schedule',
          items: [
            DetailItem('Dates', ContestList.contestDates(contest)),
            DetailItem('Timezone', contest.timezone),
          ],
        ),
        const SizedBox(height: 24),
        DetailSectionCard(
          title: 'Event',
          items: [
            DetailItem('Host', contest.host),
            DetailItem('Location', location),
          ],
        ),
        const SizedBox(height: 24),
        DetailSectionCard(
          title: 'Status',
          items: [
            DetailItem(
              'Lifecycle',
              ContestStatusChip.label(contest.lifecycleState),
            ),
            DetailItem(
              'Scoring access',
              _capitalized(contest.scoringAccess.name),
            ),
            DetailItem('Admin lock', _capitalized(contest.adminLock.name)),
          ],
        ),
      ],
    );
  }

  static String _capitalized(String text) =>
      '${text[0].toUpperCase()}${text.substring(1)}';
}
