import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/pilot_round.dart';
import 'status_chip.dart';

/// One round on the pilot overview: the draw, who entered the score, the
/// status, and Enter (next round only) or View (scored rounds).
class PilotRoundCard extends StatelessWidget {
  const PilotRoundCard({
    required this.round,
    required this.nextRound,
    required this.onEnter,
    required this.onView,
    required this.onFlightResults,
    super.key,
  });

  final PilotRound round;

  /// The round the pilot must score before any later one opens.
  final int nextRound;
  final VoidCallback onEnter;
  final VoidCallback onView;

  /// Opens the group results; offered once a score was entered for the round.
  final VoidCallback onFlightResults;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final status = round.status;
    final isNext = status == PilotRoundStatus.nextToScore;
    final note = switch (status) {
      PilotRoundStatus.upcoming =>
        'Score round $nextRound first. Rounds open in order.',
      PilotRoundStatus.locked =>
        round.unavailableReason ?? 'This round is locked.',
      PilotRoundStatus.retired => 'You retired from this round.',
      _ => null,
    };
    final dimmed = note != null;
    // A score was entered for the group once the round is submitted or waits
    // for review.
    final hasScore =
        status == PilotRoundStatus.submitted ||
        status == PilotRoundStatus.pendingReview;
    final chip = switch (status) {
      PilotRoundStatus.submitted => const StatusChip(
        label: 'Submitted',
        icon: Icons.send_outlined,
      ),
      PilotRoundStatus.pendingReview => const StatusChip(
        label: 'Pending review',
        icon: Icons.rate_review_outlined,
      ),
      PilotRoundStatus.nextToScore => const StatusChip(
        label: 'Next to score',
        icon: Icons.edit_outlined,
        style: StatusChipStyle.filled,
      ),
      PilotRoundStatus.upcoming => const StatusChip(
        label: 'Not open yet',
        icon: Icons.schedule,
        style: StatusChipStyle.quiet,
      ),
      PilotRoundStatus.locked => const StatusChip(
        label: 'Locked',
        icon: Icons.lock_outline,
        style: StatusChipStyle.quiet,
      ),
      PilotRoundStatus.retired => const StatusChip(
        label: 'Retired',
        icon: Icons.flag_outlined,
        style: StatusChipStyle.quiet,
      ),
    };
    final draw = [
      'Group ${round.group}',
      if (round.lane != null) 'Lane ${round.lane}',
      if (round.enteredBy != null)
        round.enteredBy == 'you'
            ? 'Entered by you'
            : 'Entered by ${round.enteredBy}',
    ].join(' · ');
    return Opacity(
      opacity: dimmed ? 0.8 : 1,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isNext ? scheme.onSurface : scheme.outlineVariant,
            width: isNext ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Round ${round.number}',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  chip,
                ],
              ),
              const SizedBox(height: 6),
              Text(draw, style: theme.textTheme.bodyMedium),
              if (note != null) ...[
                const SizedBox(height: 6),
                Text(
                  note,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ] else ...[
                const SizedBox(height: 8),
                if (isNext)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: onEnter,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: const Text('Enter'),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          side: BorderSide(color: scheme.onSurface, width: 1.5),
                        ),
                        onPressed: onView,
                        icon: const Icon(Icons.visibility_outlined, size: 20),
                        label: const Text('View'),
                      ),
                      if (hasScore)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            side: BorderSide(
                              color: scheme.onSurface,
                              width: 1.5,
                            ),
                          ),
                          onPressed: onFlightResults,
                          icon: const Icon(
                            Icons.leaderboard_outlined,
                            size: 20,
                          ),
                          label: Text(
                            AppLocalizations.of(context).flightResults,
                          ),
                        ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
