import 'package:flutter/material.dart';

import 'package:soar_score_core/soar_score_core.dart';

/// Displays the generated matrix results.
class MatrixResultsView extends StatelessWidget {
  final DrawResult result;
  final Map<String, String> pilotNames;

  const MatrixResultsView({
    super.key,
    required this.result,
    required this.pilotNames,
  });

  String _pilotName(String pilotId) {
    return pilotNames[pilotId] ?? pilotId;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fairness Summary',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Maximum duplicate matchups: ${result.maxDuplicateMatchups}'),
                Text('Matchup distribution (0/1/2/3+ times): '
                    '${result.matchupHistogram[0]}/'
                    '${result.matchupHistogram[1]}/'
                    '${result.matchupHistogram[2]}/'
                    '${result.matchupHistogram[3]}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Round Assignments',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: result.rounds.length,
            itemBuilder: (context, roundIndex) {
              final round = result.rounds[roundIndex];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Text('Round ${round.roundNumber}'),
                  children: round.groups.map((group) {
                    final groupNumber = group.first.groupNumber;
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Group $groupNumber',
                              style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 4),
                          ...group.map((assignment) {
                            return Row(
                              children: [
                                Text('Lane ${assignment.laneNumber}: '),
                                Expanded(
                                  child: Text(_pilotName(assignment.pilotId)),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}