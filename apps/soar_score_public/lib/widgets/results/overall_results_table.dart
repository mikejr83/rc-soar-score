import 'package:flutter/material.dart';

import '../../models/results/pilot_standing_row.dart';
import 'pilot_standing_cells.dart';

/// Overall Individual Results as of [round]: one column per round up to it,
/// a tie indicator on shared places and dropped rounds struck through.
/// [onRoundTap] opens that round's flight groups.
class OverallResultsTable extends StatelessWidget {
  const OverallResultsTable({
    super.key,
    required this.rows,
    required this.round,
    this.onRoundTap = _ignore,
  });

  final List<PilotStandingRow> rows;
  final int round;
  final RoundTap onRoundTap;

  static const String tieIndicator = placeTieIndicator;

  static void _ignore(int round, String? pilotKey) {}

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          const DataColumn(label: Text('Place')),
          ...pilotStandingColumns(round, onRoundTap),
        ],
        rows: [
          for (final row in rows)
            DataRow(
              key: ValueKey(row.pilotKey),
              cells: [
                placeCell(row.place, row.isTied),
                ...pilotStandingCells(row, round, onRoundTap),
              ],
            ),
        ],
      ),
    );
  }
}
