import 'package:flutter/material.dart';

import '../../models/results/team_standing_row.dart';
import 'pilot_standing_cells.dart';

/// Team Scores as of [round]: a section per team whose first row carries
/// the team's place, name, score and percentage, followed by its pilots.
class TeamResultsTable extends StatelessWidget {
  const TeamResultsTable({
    super.key,
    required this.teams,
    required this.round,
    this.onRoundTap = _ignore,
  });

  final List<TeamStandingRow> teams;
  final int round;
  final RoundTap onRoundTap;

  static void _ignore(int round, String? pilotKey) {}

  @override
  Widget build(BuildContext context) {
    const empty = DataCell(Text(''));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          const DataColumn(label: Text('Place')),
          const DataColumn(label: Text('Team')),
          const DataColumn(label: Text('Team Score'), numeric: true),
          const DataColumn(label: Text('Percentage'), numeric: true),
          ...pilotStandingColumns(round, onRoundTap),
        ],
        rows: [
          for (final team in teams)
            for (final (i, pilot) in team.pilots.indexed)
              DataRow(
                key: ValueKey('${team.teamKey}_${pilot.pilotKey}'),
                cells: [
                  if (i == 0) ...[
                    placeCell(team.place, team.isTied),
                    DataCell(Text(team.name)),
                    DataCell(Text(formatScore(team.teamScore))),
                    DataCell(Text(formatPercent(team.percentOfWinner))),
                  ] else
                    ...List.filled(4, empty),
                  ...pilotStandingCells(pilot, round, onRoundTap),
                ],
              ),
        ],
      ),
    );
  }
}
