import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../models/sample_data.dart';
import '../router.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/self_score_app_bar.dart';
import '../widgets/standings_table.dart';
import '../widgets/status_chip.dart';

/// Where the pilot stands: their place and score, then the overall tables.
class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  bool _teams = false;

  static const _pilots = [
    StandingsRow(place: '1', name: 'Li Wei', score: '2,231'),
    StandingsRow(place: '2', name: 'Tom Reid', score: '2,207'),
    StandingsRow(
      place: '3',
      name: SampleData.pilotName,
      score: '2,184',
      isYou: true,
    ),
    StandingsRow(place: '3=', name: 'Ana Lopez', score: '2,184', tied: true),
    StandingsRow(place: '5', name: 'Kate Brooks', score: '2,096'),
  ];

  static const _teamRows = [
    StandingsRow(place: '1', name: 'Team Osprey', score: '412'),
    StandingsRow(
      place: '2',
      name: SampleData.teamName,
      score: '398',
      isYou: true,
      youLabel: '(your team)',
    ),
    StandingsRow(place: '3', name: 'Team Merlin', score: '371'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    return Scaffold(
      appBar: SelfScoreAppBar(
        title: 'Results',
        contextLine: SampleData.contestName,
        onBack: () => context.canPop() ? context.pop() : context.go(teamPath),
        backLabel: 'Back',
        actions: const [ConnectionIndicator()],
        showAccount: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const StatusChip(
                  label: 'Preliminary',
                  icon: Icons.pending_outlined,
                ),
                Text(
                  'After round 4',
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You are',
                      style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Semantics(
                          label: '3rd place',
                          excludeSemantics: true,
                          child: Text(
                            '3rd',
                            style: BrandTypography.stencilHero.copyWith(
                              fontSize: 56,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        Text(
                          '2,184',
                          style: BrandTypography.numbers.copyWith(
                            fontSize: 40,
                            height: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your group score. You are 3rd after round 4.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.pause_circle_outline, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          'Standings are held at round 4. The director is '
                          'hiding overall results while scores are checked.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              segments: const [
                ButtonSegment(value: false, label: Text('Pilots')),
                ButtonSegment(value: true, label: Text('Teams')),
              ],
              selected: {_teams},
              onSelectionChanged: (value) =>
                  setState(() => _teams = value.first),
            ),
            const SizedBox(height: 16),
            Text(
              _teams ? 'Overall, teams' : 'Overall, pilots',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            StandingsTable(
              nameHeader: _teams ? 'Team' : 'Pilot',
              rows: _teams ? _teamRows : _pilots,
            ),
            const SizedBox(height: 16),
            Text(
              'Scores are preliminary and can change until the director marks '
              'results official.',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
