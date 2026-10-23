import 'package:flutter/material.dart';

import 'status_chip.dart';

/// Where a team pilot stands in the running order.
enum TeamPilotState { upNow, upNext, justFlown, retired, scheduled }

/// One pilot on the team overview: name, flight slot and what is needed.
class TeamPilotTile extends StatelessWidget {
  const TeamPilotTile({
    required this.name,
    required this.pilotNumber,
    required this.slot,
    required this.state,
    this.onEnterScore,
    this.onTap,
    super.key,
  });

  final String name;
  final int pilotNumber;
  final String slot;
  final TeamPilotState state;

  /// Opens the pilot overview.
  final VoidCallback? onTap;

  /// Shown on a just-flown pilot that has no score yet.
  final VoidCallback? onEnterScore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final retired = state == TeamPilotState.retired;
    final muted = scheme.onSurfaceVariant;
    final chip = switch (state) {
      TeamPilotState.upNow => const StatusChip(
        label: 'Up now',
        icon: Icons.play_circle_outline,
        style: StatusChipStyle.filled,
      ),
      TeamPilotState.upNext => const StatusChip(
        label: 'Up next',
        icon: Icons.schedule,
      ),
      TeamPilotState.justFlown => const StatusChip(
        label: 'Just flown',
        icon: Icons.edit_note,
        style: StatusChipStyle.tonal,
      ),
      TeamPilotState.retired => const StatusChip(
        label: 'Retired',
        icon: Icons.person_off_outlined,
        style: StatusChipStyle.quiet,
      ),
      TeamPilotState.scheduled => null,
    };
    return Opacity(
      opacity: retired ? 0.7 : 1,
      child: Card(
        elevation: retired ? 0 : null,
        color: retired ? scheme.surface : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: state == TeamPilotState.upNow
                ? scheme.onSurface
                : scheme.outlineVariant,
            width: state == TeamPilotState.upNow ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: retired ? muted : null,
                            ),
                          ),
                          Text(
                            'Pilot $pilotNumber',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ?chip,
                    if (onTap != null) Icon(Icons.chevron_right, color: muted),
                  ],
                ),
                const SizedBox(height: 6),
                if (retired)
                  Text(
                    'Not flying. Future rounds count as zero.',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  )
                else
                  Text(slot, style: theme.textTheme.bodyMedium),
                if (onEnterScore != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'No score entered yet for this flight.',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      side: BorderSide(color: scheme.onSurface, width: 1.5),
                    ),
                    onPressed: onEnterScore,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: const Text('Enter score'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
