import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../services/reports/reports_facts.dart';
import '../../services/reports/result_status.dart';
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final completed = facts.isCompleted;
    return Semantics(
      container: true,
      label: l10n.reportsBuiltFrom,
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
                l10n.reportsBuiltFrom,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final items = [
                    _Fact(
                      key: const ValueKey('reports-fact-lifecycle'),
                      icon: completed ? Icons.task_alt : Icons.flag_outlined,
                      label: l10n.reportsFactLifecycle,
                      value:
                          completed &&
                              facts.resultStatus == ResultStatus.official
                          ? l10n.reportsFactCompleted
                          : ContestStatusChip.label(l10n, facts.lifecycle),
                    ),
                    if (facts.matrixRevision == null)
                      _Fact(
                        key: const ValueKey('reports-fact-matrix'),
                        icon: Icons.grid_view,
                        label: l10n.reportsFactMatrix,
                        value: l10n.reportsFactNoMatrix,
                      ),
                    if (facts.configurationRevision == null)
                      _Fact(
                        key: const ValueKey('reports-fact-configuration'),
                        icon: Icons.tune,
                        label: l10n.reportsFactConfiguration,
                        value: l10n.reportsFactNoneSaved,
                      ),
                    _Fact(
                      key: const ValueKey('reports-fact-progress'),
                      icon: _progressIcon(facts),
                      label: l10n.reportsFactScoringProgress,
                      value: facts.progressText,
                    ),
                    _ResultStatusFact(facts: facts),
                  ];
                  if (constraints.maxWidth < _stackBreakpoint) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: items,
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 28,
                    children: [for (final item in items) Expanded(child: item)],
                  );
                },
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

  /// Below this width the three facts stack instead of sharing a row.
  static const double _stackBreakpoint = 640;

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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('reports-fact-result-status'),
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(
          l10n.reportsResultStatusLead,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            Semantics(
              label: l10n.reportsResultStatusLabel(facts.resultStatus.label),
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
