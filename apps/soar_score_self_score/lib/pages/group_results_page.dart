import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/self_score_scope.dart';
import '../models/group_results.dart';
import '../router.dart';
import '../widgets/group_result_tile.dart';
import '../widgets/loadable_scaffold.dart';
import '../widgets/self_score_app_bar.dart';
import '../widgets/status_chip.dart';

/// Preliminary results for the group a pilot flew in, shown after a score is
/// entered. Participant submissions show as they arrive.
class GroupResultsPage extends StatelessWidget {
  const GroupResultsPage({
    required this.contestId,
    required this.pilotId,
    required this.roundId,
    super.key,
  });

  final String contestId;
  final String pilotId;
  final String roundId;

  @override
  Widget build(BuildContext context) {
    final repository = context.repository;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: muted,
      fontWeight: FontWeight.w600,
    );
    return LoadableScaffold<GroupResults>(
      load: () => repository.groupResults(
        contestId,
        pilotId,
        int.tryParse(roundId) ?? 0,
      ),
      reloadKey: (repository, contestId, pilotId, roundId),
      appBar: (context, data) => SelfScoreAppBar(
        title: data == null ? 'Group results' : 'Group ${data.group} results',
        contextLine: data == null
            ? null
            : '${data.contestName} · Round ${data.round}',
        onBack: () => context.canPop()
            ? context.pop()
            : context.go(pilotPath(contestId, pilotId)),
        backLabel: 'Back to score entry',
        showAccount: false,
      ),
      builder: (context, data) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const StatusChip(
                        label: 'Preliminary',
                        icon: Icons.pending_outlined,
                      ),
                      Text(
                        'Updates as scores come in',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Time, height and landing are the values entered for '
                    'each flight. A zero shows why.',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: BorderSide(color: scheme.onSurface, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            onPressed: () => context.push(
              resultsPath(contestId, asOfRound: data.latestRound),
            ),
            child: Row(
              children: [
                const Icon(Icons.leaderboard_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Overall results as of round ${data.latestRound}',
                  ),
                ),
                Icon(Icons.chevron_right, color: muted),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('Pilot and flight', style: labelStyle)),
              SizedBox(
                width: 64,
                child: Text(
                  'Time',
                  textAlign: TextAlign.right,
                  style: labelStyle,
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  'Score',
                  textAlign: TextAlign.right,
                  style: labelStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final row in data.rows) GroupResultTile(row: row),
          const SizedBox(height: 16),
          Text(
            'Scores are preliminary. The director can change them until '
            'results are official.',
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
