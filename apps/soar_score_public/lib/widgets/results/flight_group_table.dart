import 'package:flutter/material.dart';

import '../../models/results/flight_group.dart';
import 'pilot_standing_cells.dart';

/// One flight group's table headed by its group and re-flight number.
///
/// Time and the discipline details show only when the group's flights carry
/// raw components (#456); the landing column only when [hasLanding]. The
/// flight of [highlightPilotKey] is selected and carries [highlightKey] so
/// the page can scroll to it.
class FlightGroupTable extends StatelessWidget {
  const FlightGroupTable({
    super.key,
    required this.group,
    required this.hasLanding,
    this.highlightPilotKey,
    this.highlightKey,
  });

  final FlightGroup group;
  final bool hasLanding;
  final String? highlightPilotKey;
  final Key? highlightKey;

  /// `launch_height` reads as `Launch height` until #456 carries labels.
  static String label(String key) {
    final words = key.replaceAll('_', ' ');
    return words[0].toUpperCase() + words.substring(1);
  }

  /// Seconds as `m:ss`, with tenths when the time has them.
  static String formatTime(Object? value) {
    if (value is! num) return value?.toString() ?? '-';
    final minutes = value ~/ 60;
    final seconds = value - minutes * 60;
    final text = seconds == seconds.roundToDouble()
        ? seconds.toInt().toString().padLeft(2, '0')
        : seconds.toStringAsFixed(1).padLeft(4, '0');
    return '$minutes:$text';
  }

  @override
  Widget build(BuildContext context) {
    const strike = TextStyle(decoration: TextDecoration.lineThrough);
    final raw = group.hasRawComponents;
    final details = group.detailKeys;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(group.title, style: Theme.of(context).textTheme.titleMedium),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('Name')),
              const DataColumn(label: Text('Country')),
              if (raw) const DataColumn(label: Text('Time'), numeric: true),
              if (hasLanding)
                const DataColumn(label: Text('Landing'), numeric: true),
              for (final key in details)
                DataColumn(label: Text(label(key)), numeric: true),
              const DataColumn(label: Text('Points'), numeric: true),
              const DataColumn(label: Text('Score'), numeric: true),
              const DataColumn(label: Text('Penalty'), numeric: true),
            ],
            rows: [
              for (final f in group.flights)
                DataRow(
                  selected: f.pilotKey == highlightPilotKey,
                  cells: [
                    DataCell(
                      Text(
                        f.name,
                        key: f.isSelected && f.pilotKey == highlightPilotKey
                            ? highlightKey
                            : null,
                      ),
                    ),
                    DataCell(Text(f.country)),
                    if (raw) DataCell(Text(formatTime(f.time))),
                    if (hasLanding)
                      DataCell(Text(formatScore(f.landingPoints))),
                    for (final key in details)
                      DataCell(Text(f.rawComponents[key]?.toString() ?? '-')),
                    DataCell(Text(formatScore(f.rawPoints))),
                    DataCell(
                      Tooltip(
                        message: f.isSelected ? '' : 'Replaced by a re-flight',
                        child: Text(
                          formatScore(f.groupScore),
                          style: f.isSelected ? null : strike,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        f.penaltyPoints == 0
                            ? '-'
                            : formatScore(f.penaltyPoints),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
