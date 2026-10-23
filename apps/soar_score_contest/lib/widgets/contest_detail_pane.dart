import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../l10n/app_localizations.dart';
import '../services/contest_open_action.dart';
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
    this.inspection = false,
    this.onExport,
  });

  final Contest contest;
  final VoidCallback onOpen;
  final VoidCallback? onBack;

  /// Whether the contest is a local copy imported for inspection, which is
  /// never synced.
  final bool inspection;

  /// Exports the contest to a file; `null` when this build cannot.
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ContestStatusChip(state: contest.lifecycleState),
                      if (inspection)
                        Chip(
                          key: const ValueKey('inspection-label'),
                          avatar: const Icon(Icons.cloud_off, size: 16),
                          label: Text(l10n.inspectionChipLabel),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            if (onExport != null) ...[
              OutlinedButton.icon(
                key: const ValueKey('export-contest'),
                onPressed: onExport,
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: Text(l10n.exportContestButton),
              ),
              const SizedBox(width: 8),
            ],
            FilledButton.icon(
              key: const ValueKey('open-contest'),
              onPressed: onOpen,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(ContestOpenAction.of(contest).label),
            ),
          ],
        ),
        if (inspection) ...[
          const SizedBox(height: 16),
          Text(
            l10n.inspectionNotice,
            key: const ValueKey('inspection-notice'),
            style: theme.textTheme.bodyMedium,
          ),
        ],
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
