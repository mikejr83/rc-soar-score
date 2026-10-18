import 'package:flutter/material.dart';

import '../../models/results/pilot_standing_row.dart';

/// Overall Individual Results as of [round]: one column per round up to it,
/// a tie indicator on shared places and dropped rounds struck through.
class OverallResultsTable extends StatelessWidget {
  const OverallResultsTable({
    super.key,
    required this.rows,
    required this.round,
  });

  final List<PilotStandingRow> rows;
  final int round;

  static const String tieIndicator = '=';

  static String score(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  static String percent(double value) {
    final text = value.toStringAsFixed(1);
    return '${text.endsWith('.0') ? text.substring(0, text.length - 2) : text}%';
  }

  @override
  Widget build(BuildContext context) {
    final strike = const TextStyle(decoration: TextDecoration.lineThrough);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          const DataColumn(label: Text('Place')),
          const DataColumn(label: Text('Name')),
          const DataColumn(label: Text('Country')),
          const DataColumn(label: Text('Score'), numeric: true),
          const DataColumn(label: Text('Percentage'), numeric: true),
          const DataColumn(label: Text('Raw Score'), numeric: true),
          for (var r = 1; r <= round; r++)
            DataColumn(label: Text('Round $r'), numeric: true),
          const DataColumn(label: Text('Penalty'), numeric: true),
        ],
        rows: [
          for (final row in rows)
            DataRow(
              key: ValueKey(row.pilotKey),
              cells: [
                DataCell(
                  Text(
                    row.isTied ? '${row.place}$tieIndicator' : '${row.place}',
                    semanticsLabel: row.isTied
                        ? 'Place ${row.place}, tied'
                        : 'Place ${row.place}',
                  ),
                ),
                DataCell(Text(row.name)),
                DataCell(Text(row.country)),
                DataCell(Text(score(row.overallScore))),
                DataCell(Text(percent(row.percentOfWinner))),
                DataCell(Text(score(row.rawTotal))),
                for (var r = 1; r <= round; r++)
                  DataCell(
                    Tooltip(
                      message: row.droppedRounds.contains(r) ? 'Dropped' : '',
                      child: Text(switch (row.roundScores[r]) {
                        null => '-',
                        final value => score(value),
                      }, style: row.droppedRounds.contains(r) ? strike : null),
                    ),
                  ),
                DataCell(
                  Text(row.penaltyTotal == 0 ? '-' : score(row.penaltyTotal)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
