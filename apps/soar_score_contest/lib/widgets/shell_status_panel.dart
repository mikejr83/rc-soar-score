import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../services/workspace/workspace_control_target.dart';
import 'contest_status_chip.dart';

/// The selected contest's high-level status, shown under the shell header on
/// every contest page: `Status` (the lifecycle state), `Participant scoring`
/// and `Administration`. The values stay separate, never combined into one
/// (`plan/ui/contest-administration/README.md`, "Contest state presentation").
///
/// The panel never changes a value. Each one is a button that calls [onOpen]
/// to take the director to the control that does, on the workspace.
class ShellStatusPanel extends StatelessWidget {
  const ShellStatusPanel({super.key, required this.contest, this.onOpen});

  final Contest contest;

  /// Called with the control to go to; the values are plain text when `null`.
  final ValueChanged<WorkspaceControlTarget>? onOpen;

  VoidCallback? _tap(WorkspaceControlTarget target) {
    final open = onOpen;
    return open == null ? null : () => open(target);
  }

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
              onTap: _tap(WorkspaceControlTarget.lifecycle),
              theme: theme,
              icon: Icons.flag_outlined,
              value: ContestStatusChip.label(contest.lifecycleState),
            ),
            _Item(
              label: 'Participant scoring',
              onTap: _tap(WorkspaceControlTarget.scoring),
              theme: theme,
              icon: Icons.sports_score,
              value: scoringOpen ? 'Open' : 'Closed',
            ),
            _Item(
              label: 'Administration',
              onTap: _tap(WorkspaceControlTarget.administration),
              theme: theme,
              icon: locked ? Icons.lock : Icons.lock_open,
              value: locked ? 'Locked' : 'Unlocked',
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
    required this.value,
    required this.icon,
    required this.theme,
    required this.onTap,
  });

  final String label;

  /// The value as text, for the accessible name.
  final String value;
  final IconData icon;
  final ThemeData theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
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
        Text(
          value,
          style: theme.textTheme.bodySmall!.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
    if (onTap == null) {
      return content;
    }
    return Semantics(
      button: true,
      label: '$label: $value. Go to the ${label.toLowerCase()} control',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(widthFactor: 1, child: content),
          ),
        ),
      ),
    );
  }
}
