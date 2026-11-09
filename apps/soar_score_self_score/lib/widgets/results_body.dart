import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soar_score_ui/soar_score_ui.dart';

import '../models/results_snapshot.dart';
import '../models/results_view.dart';
import '../router.dart';
import 'earlier_round_banner.dart';
import 'standings_table.dart';
import 'status_chip.dart';

/// The results content: the viewer's place, the held-standings note and the
/// pilots/teams tables. Holds which table is showing.
class ResultsBody extends StatefulWidget {
  const ResultsBody({required this.contestId, required this.data, super.key});

  final String contestId;
  final ResultsView data;

  @override
  State<ResultsBody> createState() => _ResultsBodyState();
}

class _ResultsBodyState extends State<ResultsBody> {
  bool _teams = false;

  List<StandingsRow> _rows(List<StandingLine> lines) => [
    for (final line in lines)
      StandingsRow(
        place: line.place,
        name: line.name,
        score: line.score,
        isYou: line.isYou,
        youLabel: _teams ? '(your team)' : '(you)',
        tied: line.tied,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final data = widget.data;
    final snapshot = data.snapshot;
    final round = snapshot.round;
    final isLatest = data.isLatest;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!isLatest) ...[
          EarlierRoundBanner(
            round: round,
            latest: data.latestRound,
            onSeeLatest: () => context.go(resultsPath(widget.contestId)),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const StatusChip(
              label: 'Preliminary',
              icon: Icons.pending_outlined,
            ),
            Text(
              isLatest ? 'As of round $round · latest' : 'As of round $round',
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
                  isLatest ? 'You are' : 'You were',
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Semantics(
                      label: '${snapshot.ordinal} place',
                      excludeSemantics: true,
                      child: Text(
                        snapshot.ordinal,
                        style: BrandTypography.stencilHero.copyWith(
                          fontSize: 56,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      snapshot.score,
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
                  'Your group score. You ${isLatest ? 'are' : 'were'} '
                  '${snapshot.ordinal} after round $round.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              ],
            ),
          ),
        ),
        if (data.heldRound != null) ...[
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.pause_circle_outline, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        'Standings are held at round ${data.heldRound}. '
                        'The director is hiding overall results while scores '
                        'are checked.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        // Team standings only show when the contest has teams.
        if (snapshot.teams.isNotEmpty) ...[
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
            onSelectionChanged: (value) => setState(() => _teams = value.first),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          '${_teams ? 'Overall, teams' : 'Overall, pilots'}'
          '${isLatest ? '' : ', as of round $round'}',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        StandingsTable(
          nameHeader: _teams ? 'Team' : 'Pilot',
          rows: _rows(_teams ? snapshot.teams : snapshot.pilots),
        ),
        const SizedBox(height: 16),
        Text(
          isLatest
              ? 'Scores are preliminary and can change until the director '
                    'marks results official.'
              : 'Results as of round $round are preliminary. A review that '
                    'changes round $round updates this page.',
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
      ],
    );
  }
}
