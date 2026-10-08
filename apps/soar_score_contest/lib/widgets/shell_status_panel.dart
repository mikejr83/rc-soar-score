import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'contest_status_chip.dart';

/// The selected contest's high-level status, shown under the shell header on
/// every contest page: `Status` (the lifecycle state), `Participant scoring`
/// and `Administration`. The values stay separate, never combined into one
/// (`plan/ui/contest-administration/README.md`, "Contest state presentation").
class ShellStatusPanel extends StatelessWidget {
  const ShellStatusPanel({super.key, required this.contest});

  final Contest contest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = contest.adminLock == AdminLock.locked;
    final scoringOpen = contest.scoringAccess == ScoringAccess.open;
    return Semantics(
      container: true,
      label: 'Contest status',
      child: Padding(
        key: const ValueKey('shell-status-panel'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Wrap(
          spacing: 24,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Item(
              label: 'Status',
              theme: theme,
              icon: Icons.flag_outlined,
              child: Text(ContestStatusChip.label(contest.lifecycleState)),
            ),
            _Item(
              label: 'Participant scoring',
              theme: theme,
              icon: Icons.sports_score,
              child: Text(scoringOpen ? 'Open' : 'Closed'),
            ),
            _Item(
              label: 'Administration',
              theme: theme,
              icon: locked ? Icons.lock : Icons.lock_open,
              child: Text(locked ? 'Locked' : 'Unlocked'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.label,
    required this.child,
    required this.icon,
    required this.theme,
  });

  final String label;
  final Widget child;
  final IconData icon;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
      const SizedBox(width: 6),
      Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(width: 6),
      DefaultTextStyle.merge(
        style: theme.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500),
        child: child,
      ),
    ],
  );
}
