import 'package:flutter/material.dart';

import '../../services/new_contest/draw_settings.dart';

/// The live pilots-per-group calculation for step 6 (a polite live region),
/// with each constraint marked OK or Blocked by icon and text.
class GroupCalculationPanel extends StatelessWidget {
  const GroupCalculationPanel({
    super.key,
    required this.plan,
    required this.teamsOn,
  });

  final GroupPlan plan;
  final bool teamsOn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final groups = plan.groups;

    final constraints = <(IconData, Color, String, String)>[
      plan.bigEnough
          ? (
              Icons.check_circle,
              scheme.secondary,
              'OK:',
              'every group has at least 2 scoring pilots.',
            )
          : (
              Icons.error,
              scheme.error,
              'Blocked:',
              plan.groupsValid
                  ? 'with $groups groups some would have fewer than 2 '
                        'scoring pilots. Use ${plan.maxGroups} or fewer.'
                  : 'enter at least 1 group.',
            ),
      if (plan.teamProtection)
        (
          plan.protectionMet ? Icons.check_circle : Icons.error,
          plan.protectionMet ? scheme.secondary : scheme.error,
          plan.protectionMet ? 'OK:' : 'Blocked:',
          'team protection needs at least ${plan.minGroups} groups. Your '
              'largest team has ${plan.largestTeam} scoring pilots.',
        )
      else if (teamsOn)
        (
          Icons.info,
          muted,
          '',
          'Team protection is off, so teammates can share a group.',
        ),
    ];

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        key: const ValueKey('group-calculation'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PILOTS PER GROUP · UPDATES AS YOU EDIT',
              style: theme.textTheme.labelSmall?.copyWith(
                color: muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              plan.groupsValid ? '${plan.perGroupText} pilots' : '—',
              key: const ValueKey('pilots-per-group'),
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              plan.groupsValid
                  ? '${plan.scoring} scoring pilots in $groups '
                        'group${groups == 1 ? '' : 's'} · smallest group '
                        '${plan.smallestGroup}, largest ${plan.largestGroup}'
                  : '${plan.scoring} scoring pilots',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            if (plan.groupsValid) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final (index, size) in plan.sizes.indexed)
                    Container(
                      constraints: const BoxConstraints(minWidth: 56),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        border: Border.all(
                          color: size < 2
                              ? scheme.error
                              : scheme.outlineVariant,
                          width: size < 2 ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'G${index + 1}',
                            style: theme.textTheme.labelMedium,
                          ),
                          Text(
                            '$size',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Divider(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: 10),
            for (final (icon, color, state, text) in constraints)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 20, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            if (state.isNotEmpty)
                              TextSpan(
                                text: '$state ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            TextSpan(text: text),
                          ],
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
