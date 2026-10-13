import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../router.dart';
import '../../../services/workspace/progress/progress_summary.dart';
import '../../../services/workspace/progress/progress_text.dart';
import '../workspace_scope.dart';
import 'progress_card.dart';

/// The progress section of the workspace: reduces the workspace facts to a
/// summary and sends a tapped tile to Scoring at its round.
class ProgressSection extends StatelessWidget {
  const ProgressSection({super.key, required this.contest});

  final Contest contest;

  @override
  Widget build(BuildContext context) {
    final scope = WorkspaceScope.of(context);
    final facts = scope.facts;
    if (facts == null) {
      return _Placeholder(
        onRetry: scope.factsFailed ? scope.reloadFacts : null,
      );
    }
    return ProgressCard(
      summary: ProgressSummary.of(facts),
      zoneId: contest.timezone,
      onOpenRound: (ordinal) =>
          context.go(contestScoringPath(contest.id.value, round: ordinal)),
      onRetry: scope.reloadFacts,
    );
  }
}

/// The card while the facts load, and when they could not be loaded at all.
class _Placeholder extends StatelessWidget {
  const _Placeholder({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('progress-placeholder'),
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: onRetry == null
            ? Row(
                children: [
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ProgressText.loading,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              )
            : Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: [
                  Text(
                    ProgressText.unavailable,
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    key: const ValueKey('progress-retry'),
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
      ),
    );
  }
}
