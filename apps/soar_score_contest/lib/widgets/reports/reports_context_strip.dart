import 'package:flutter/material.dart';

import '../../services/reports/reports_facts.dart';
import '../contest_status_chip.dart';
import 'reports_offline_note.dart';
import 'result_status_chip.dart';
import 'result_status_help.dart';

/// One compact strip above the list that says what a report would be built
/// from, so a printout can be tied back to this state. Lifecycle is the only
/// one of the shell's three status values it repeats; it is never merged with
/// the result status.
class ReportsContextStrip extends StatelessWidget {
  const ReportsContextStrip({
    super.key,
    required this.facts,
    required this.offline,
    required this.onOpenSync,
  });

  final ReportsFacts facts;
  final bool offline;

  /// Opens the sync page; `null` in a build that does not synchronize.
  final VoidCallback? onOpenSync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final completed = facts.isCompleted;
    return Semantics(
      container: true,
      label: 'Reports are built from',
      child: DecoratedBox(
        key: const ValueKey('reports-context-strip'),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text(
                'Reports are built from',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Wrap(
                spacing: 28,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                  _Fact(
                    key: const ValueKey('reports-fact-lifecycle'),
                    icon: completed ? Icons.task_alt : Icons.flag_outlined,
                    label: 'Lifecycle',
                    value: completed
                        ? 'Completed · Results are final'
                        : ContestStatusChip.label(facts.lifecycle),
                  ),
                  _Fact(
                    key: const ValueKey('reports-fact-matrix'),
                    icon: Icons.grid_view,
                    label: 'Matrix',
                    value: facts.matrixRevision == null
                        ? 'No matrix drawn'
                        : 'Revision ${facts.matrixRevision}',
                  ),
                  _Fact(
                    key: const ValueKey('reports-fact-configuration'),
                    icon: Icons.tune,
                    label: 'Configuration',
                    value: facts.configurationRevision == null
                        ? 'None saved'
                        : 'Revision ${facts.configurationRevision}',
                  ),
                  _Fact(
                    key: const ValueKey('reports-fact-progress'),
                    icon: _progressIcon(facts),
                    label: 'Scoring progress',
                    value: facts.progressText,
                  ),
                  _ResultStatusFact(facts: facts),
                ],
              ),
              if (offline)
                ReportsOfflineNote(
                  contestId: facts.contest.id,
                  onOpenSync: onOpenSync,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _progressIcon(ReportsFacts facts) {
    if (facts.rounds.isNotEmpty &&
        facts.fullyScoredRounds == facts.rounds.length) {
      return Icons.check_circle_outline;
    }
    return facts.hasScores ? Icons.timelapse : Icons.hourglass_empty;
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Icon(icon, size: 20, color: muted),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultStatusFact extends StatelessWidget {
  const _ResultStatusFact({required this.facts});

  final ReportsFacts facts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('reports-fact-result-status'),
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(
          'Standings produced now would be',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            Semantics(
              label: 'Result status: ${facts.resultStatus.label}',
              excludeSemantics: true,
              child: ResultStatusChip(status: facts.resultStatus),
            ),
            const ResultStatusHelp(),
          ],
        ),
      ],
    );
  }
}
