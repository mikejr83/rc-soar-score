import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/sample_data.dart';
import '../router.dart';
import '../widgets/connection_indicator.dart';
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
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: SelfScoreAppBar(
        title: 'Team overview',
        contextLine: SampleData.contestName,
        onBack: () => context.go(contestsPath),
        backLabel: 'Back to Contests',
        actions: const [ConnectionIndicator()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(SampleData.teamName, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Your pilots. Who flies next, and who needs a score.',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: 16),
            Text('Pilots', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            TeamPilotTile(
              name: 'Jane Smith',
              pilotNumber: 12,
              slot: 'Round 4 · Group B · Lane 1',
              state: TeamPilotState.upNow,
              onTap: () => context.push(pilotPath(contestId, '12')),
            ),
            const SizedBox(height: 8),
            TeamPilotTile(
              name: 'Tom Reid',
              pilotNumber: 7,
              slot: 'Round 4 · Group C · Lane 3',
              state: TeamPilotState.upNext,
              onTap: () => context.push(pilotPath(contestId, '7')),
            ),
            const SizedBox(height: 8),
            TeamPilotTile(
              name: 'Ana Lopez',
              pilotNumber: 3,
              slot: 'Round 3 · Group A · Lane 2',
              state: TeamPilotState.justFlown,
              onTap: () => context.push(pilotPath(contestId, '3')),
              onEnterScore: () =>
                  context.push(scoreEntryPath(contestId, '3', '3')),
            ),
            const SizedBox(height: 8),
            TeamPilotTile(
              name: 'Sam Park',
              pilotNumber: 21,
              slot: '',
              state: TeamPilotState.retired,
              onTap: () => context.push(pilotPath(contestId, '21')),
            ),
            const SizedBox(height: 8),
            TeamPilotTile(
              name: 'Li Wei',
              pilotNumber: 15,
              slot: 'Round 5 · Group D · Lane 4',
              state: TeamPilotState.scheduled,
              onTap: () => context.push(pilotPath(contestId, '15')),
            ),
            const SizedBox(height: 8),
            TeamPilotTile(
              name: 'Kate Brooks',
              pilotNumber: 9,
              slot: 'Round 5 · Group D · Lane 2',
              state: TeamPilotState.scheduled,
              onTap: () => context.push(pilotPath(contestId, '9')),
            ),
            const SizedBox(height: 10),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Team standings', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const StandingsTable(
                      nameHeader: 'Team',
                      rows: [
                        StandingsRow(
                          place: '1',
                          name: 'Team Osprey',
                          score: '412',
                        ),
                        StandingsRow(
                          place: '2',
                          name: SampleData.teamName,
                          score: '398',
                          isYou: true,
                          youLabel: '(your team)',
                        ),
                        StandingsRow(
                          place: '3',
                          name: 'Team Merlin',
                          score: '371',
                        ),
                      ],
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
      ),
    );
  }
}
