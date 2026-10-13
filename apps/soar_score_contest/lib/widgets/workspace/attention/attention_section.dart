import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../../router.dart';
import '../../../services/workspace/attention/needs_attention.dart';
import '../../../services/workspace/attention/sync_source.dart';
import '../../sync/sync_summary_builder.dart';
import '../workspace_scope.dart';
import 'needs_attention_card.dart';

/// The needs-attention section of the workspace: reads the facts through the
/// sources and sends a row's link to the page that fixes it.
class AttentionSection extends StatelessWidget {
  const AttentionSection({super.key, required this.contest});

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
    return SyncSummaryBuilder(
      scope: ContestScopeKey(contest.id),
      builder: (context, sync, summary, syncing) => NeedsAttentionCard(
        attention: NeedsAttention.of(
          facts,
          sources: [...NeedsAttention.defaultSources, SyncSource(summary)],
        ),
        onRetry: scope.reloadFacts,
        onOpen: (item) {
          if (item.opensSync) {
            context.go(contestSyncPath(contest.id.value));
            return;
          }
          final round = item.scoringRound;
          context.go(contestScoringPath(contest.id.value, round: round));
        },
      ),
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
      key: const ValueKey('attention-placeholder'),
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
                      'Checking what needs attention…',
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
                    NeedsAttention.incompleteText,
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    key: const ValueKey('attention-retry'),
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
      ),
    );
  }
}
