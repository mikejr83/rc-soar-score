import 'package:flutter/material.dart';

import '../../models/results/pilot_standing_row.dart';

/// A tap on a round header (`pilotKey` null) or on one pilot's round score.
typedef RoundTap = void Function(int round, String? pilotKey);

/// The tie indicator after a shared place.
const String placeTieIndicator = '=';

String formatScore(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

String formatPercent(double value) {
  final text = value.toStringAsFixed(1);
  return '${text.endsWith('.0') ? text.substring(0, text.length - 2) : text}%';
}

/// The pilot columns the overall and team tables share: name, country,
/// score, percentage, raw score, one round per column and penalty.
List<DataColumn> pilotStandingColumns(int round, RoundTap onRoundTap) => [
  const DataColumn(label: Text('Name')),
  const DataColumn(label: Text('Country')),
  const DataColumn(label: Text('Score'), numeric: true),
  const DataColumn(label: Text('Percentage'), numeric: true),
  const DataColumn(label: Text('Raw Score'), numeric: true),
  for (var r = 1; r <= round; r++)
    DataColumn(
      numeric: true,
      label: InkWell(
        key: roundHeaderKey(r),
        onTap: () => onRoundTap(r, null),
        child: Text('Round $r'),
      ),
    ),
  const DataColumn(label: Text('Penalty'), numeric: true),
];

/// The cells matching [pilotStandingColumns] for [row].
List<DataCell> pilotStandingCells(
  PilotStandingRow row,
  int round,
  RoundTap onRoundTap,
) {
  const strike = TextStyle(decoration: TextDecoration.lineThrough);
  return [
    DataCell(Text(row.name)),
    DataCell(Text(row.country)),
    DataCell(Text(formatScore(row.overallScore))),
    DataCell(Text(formatPercent(row.percentOfWinner))),
    DataCell(Text(formatScore(row.rawTotal))),
    for (var r = 1; r <= round; r++)
      DataCell(
        Tooltip(
          message: row.droppedRounds.contains(r) ? 'Dropped' : '',
          child: Text(switch (row.roundScores[r]) {
            null => '-',
            final value => formatScore(value),
          }, style: row.droppedRounds.contains(r) ? strike : null),
        ),
        onTap: () => onRoundTap(r, row.pilotKey),
      ),
    DataCell(Text(row.penaltyTotal == 0 ? '-' : formatScore(row.penaltyTotal))),
  ];
}

/// A place cell with the tie indicator and a spoken label.
DataCell placeCell(int place, bool isTied) => DataCell(
  Text(
    isTied ? '$place$placeTieIndicator' : '$place',
    semanticsLabel: isTied ? 'Place $place, tied' : 'Place $place',
  ),
);

Key roundHeaderKey(int round) => ValueKey('round_header_$round');
