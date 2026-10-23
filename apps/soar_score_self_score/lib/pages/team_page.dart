import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/self_score_scope.dart';
import '../models/results_snapshot.dart';
import '../models/team_overview.dart';
import '../router.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/loadable_scaffold.dart';
import '../widgets/self_score_app_bar.dart';
import '../widgets/standings_table.dart';
import '../widgets/team_pilot_tile.dart';

/// The helper's view of their team: who flies next, who needs a score, and
/// where the team stands.
class TeamPage extends StatelessWidget {
  const TeamPage({required this.contestId, super.key});

  final String contestId;

  @override
  Widget build(BuildContext context) {
    final repository = context.repository;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return LoadableScaffold<TeamOverview>(
      load: () => repository.teamOverview(contestId),
      reloadKey: (repository, contestId),
      appBar: (context, data) => SelfScoreAppBar(
        title: 'Team overview',
        contextLine: data?.contestName,
        onBack: () => context.go(contestsPath),
        backLabel: 'Back to Contests',
        actions: const [ConnectionIndicator()],
      ),
      builder: (context, data) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(data.teamName, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Your pilots. Who flies next, and who needs a score.',
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: 16),
          Text('Pilots', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final pilot in data.pilots) ...[
            TeamPilotTile(
              name: pilot.name,
              pilotNumber: pilot.number,
              slot: pilot.slot,
              state: pilot.state,
              onTap: () => context.push(pilotPath(contestId, pilot.id)),
              onEnterScore: pilot.needsScoreRound == null
                  ? null
                  : () => context.push(
                      scoreEntryPath(
                        contestId,
                        pilot.id,
                        pilot.needsScoreRound!,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'These labels use entered scores, so they can lag what is '
                  'happening on the field.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Team standings', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  StandingsTable(
                    nameHeader: 'Team',
                    rows: [for (final line in data.standings) _row(line)],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.push(resultsPath(contestId)),
            child: const Text('See all results'),
          ),
        ],
      ),
    );
  }

  StandingsRow _row(StandingLine line) => StandingsRow(
    place: line.place,
    name: line.name,
    score: line.score,
    isYou: line.isYou,
    youLabel: '(your team)',
    tied: line.tied,
  );
}
