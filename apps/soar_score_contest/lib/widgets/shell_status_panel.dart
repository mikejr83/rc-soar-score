import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../l10n/app_localizations.dart';
import '../services/workspace/shell_round_item.dart';
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
  const ShellStatusPanel({
    super.key,
    required this.contest,
    this.onOpen,
    this.round,
    this.onOpenRound,
    this.trailing,
  });

  final Contest contest;

  /// The round being scored, when known; the panel shows no round entry when
  /// `null`.
  final ShellRoundItem? round;

  /// Called when the round entry is chosen, to open the scoring page.
  final ValueChanged<ShellRoundItem>? onOpenRound;

  /// An extra entry after the contest's values, for example the sync status.
  final Widget? trailing;

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
    final round = this.round;
    final l10n = AppLocalizations.of(context);
    final openRound = onOpenRound;
    final scoringOpen = contest.scoringAccess == ScoringAccess.open;
    return Semantics(
      container: true,
      label: l10n.shellStatusPanelLabel,
      child: Padding(
        key: const ValueKey('shell-status-panel'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Wrap(
          spacing: 24,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Item(
              label: l10n.shellStatusLifecycle,
              semanticsTarget: 'lifecycle',
              onTap: _tap(WorkspaceControlTarget.lifecycle),
              theme: theme,
              icon: Icons.flag_outlined,
              value: ContestStatusChip.label(l10n, contest.lifecycleState),
            ),
            _Item(
              label: l10n.shellStatusScoring,
              semanticsTarget: 'scoring',
              onTap: _tap(WorkspaceControlTarget.scoring),
              theme: theme,
              icon: Icons.sports_score,
              value: scoringOpen
                  ? l10n.shellScoringOpen
                  : l10n.shellScoringClosed,
            ),
            _Item(
              label: l10n.shellStatusAdministration,
              semanticsTarget: 'administration',
              onTap: _tap(WorkspaceControlTarget.administration),
              theme: theme,
              icon: locked ? Icons.lock : Icons.lock_open,
              value: locked ? l10n.shellAdminLocked : l10n.shellAdminUnlocked,
            ),
            if (round != null)
              _Item(
                key: const ValueKey('shell-round-status'),
                label: l10n.shellRoundLabel,
                onTap: openRound == null ? null : () => openRound(round),
                theme: theme,
                icon: Icons.format_list_numbered,
                value: _roundValue(l10n, round),
                semanticsLabel: l10n.shellRoundSemantics(
                  l10n.shellRoundLabel,
                  _roundValue(l10n, round),
                ),
              ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

String _roundValue(AppLocalizations l10n, ShellRoundItem item) =>
    switch (item.kind) {
      ShellRoundKind.notStarted => l10n.shellRoundNotStarted,
      ShellRoundKind.finished => l10n.shellRoundFinished,
      ShellRoundKind.inProgress =>
        item.groupLetter == null
            ? l10n.shellRoundValue(item.round!, item.total!)
            : l10n.shellRoundGroupValue(
                item.round!,
                item.total!,
                item.groupLetter!,
              ),
    };

class _Item extends StatelessWidget {
  const _Item({
    super.key,
    this.semanticsLabel,
    this.semanticsTarget = 'other',
    required this.label,
    required this.value,
    required this.icon,
    required this.theme,
    required this.onTap,
  });

  final String label;

  /// Overrides the accessible name of the button.
  final String? semanticsLabel;

  /// Which control the button opens, for the default accessible name.
  final String semanticsTarget;

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
      label:
          semanticsLabel ??
          AppLocalizations.of(context)
              .shellStatusSemantics(label, value, semanticsTarget),
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
