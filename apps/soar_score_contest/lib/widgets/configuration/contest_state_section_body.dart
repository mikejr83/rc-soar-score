import 'package:flutter/material.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../services/configuration/section_id.dart';

/// The Scoring access and Administration lock sections: the current value in
/// words and the way to change it. Both are contest controls that act at once
/// from the Workspace, not settings saved with the configuration.
class ContestStateSectionBody extends StatelessWidget {
  const ContestStateSectionBody({
    super.key,
    required this.id,
    required this.contest,
    required this.onOpenWorkspace,
  }) : assert(id == SectionId.scoringAccess || id == SectionId.adminLock);

  final SectionId id;
  final Contest contest;
  final VoidCallback onOpenWorkspace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (icon, value, detail) = switch (id) {
      SectionId.scoringAccess
          when contest.scoringAccess == ScoringAccess.open =>
        (Icons.lock_open, 'Open', 'Participants can submit scores.'),
      SectionId.scoringAccess => (
        Icons.block,
        'Closed',
        'Participants can’t submit scores.',
      ),
      _ when contest.adminLock == AdminLock.locked => (
        Icons.lock_outline,
        'Locked',
        'The configuration, participants and matrix are read-only.',
      ),
      _ => (Icons.lock_open, 'Unlocked', 'The contest can be administered.'),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Icon(icon, size: 20, color: scheme.onSurfaceVariant),
              Text(
                value,
                key: ValueKey('state-${id.name}'),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          Text(
            detail,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          OutlinedButton.icon(
            onPressed: onOpenWorkspace,
            icon: const Icon(Icons.dashboard_outlined, size: 18),
            label: const Text('Change in Workspace'),
          ),
        ],
      ),
    );
  }
}
