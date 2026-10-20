import 'package:intl/intl.dart';

import '../report_pilot.dart';
import '../reports_facts.dart';
import 'standings_options.dart';
import 'standings_report_data.dart';

/// One pilot's score in one round.
class StandingsCell {
  const StandingsCell({this.score, this.dropped = false, this.detail});

  /// The round score; `null` when the pilot has no score in the round.
  final double? score;

  /// The round was dropped from the total.
  final bool dropped;

  /// What was recorded for the flight, when Flight details is on.
  final FlightDetail? detail;
}

/// One pilot's line of the standings.
class StandingsRow {
  const StandingsRow({
    required this.place,
    required this.isTied,
    required this.pilot,
    required this.total,
    required this.raw,
    required this.penalty,
    required this.percentage,
    required this.cells,
    required this.reviewOpen,
  });

  final int place;
  final bool isTied;
  final ReportPilot pilot;

  /// Kept round scores less the penalty.
  final double total;

  /// The total plus the dropped rounds: every round score, less the penalty.
  final double raw;

  /// The penalty deducted from the total; 0 for none.
  final double penalty;

  /// The total as a percentage of the winner's; `null` when the winner has
  /// nothing to compare with.
  final double? percentage;

  /// The shown rounds, by ordinal.
  final Map<int, StandingsCell> cells;

  /// A score in a shown round is under review. Screen only.
  final bool reviewOpen;
}

/// The Overall Standings as a table: the rows in rank order with the round
/// scores the sheet shows. Rank and total are the stored standing as of the
/// last round shown; nothing is recalculated here.
class StandingsTable {
  StandingsTable._({
    required this.rows,
    required this.options,
    required this.rounds,
    required this.hasPenalty,
    required this.hasTie,
    required this.isF3j,
  });

  /// Builds the table for [options] from the stored [data].
  factory StandingsTable.build({
    required ReportsFacts facts,
    required StandingsOptions options,
    required StandingsReportData data,
  }) {
    final pilots = {for (final p in facts.pilots) p.participationId: p};
    final rounds = options.rounds;
    final showDetails = options.details;
    final standings = [
      for (final standing in data.results.standings)
        if (pilots.containsKey(standing.contestParticipationId)) standing,
    ];
    final top = standings.isEmpty ? 0.0 : standings.first.overallScore;
    final rows = <StandingsRow>[];
    for (final standing in standings) {
      final pilot = pilots[standing.contestParticipationId]!;
      final cells = <int, StandingsCell>{};
      var reviewOpen = false;
      for (final round in rounds) {
        final flight = data.flights[round]?[pilot.participationId];
        final detailsOfRound = showDetails ? data.details[round] : null;
        final retired =
            pilot.retiredAtRound != null && round >= pilot.retiredAtRound!;
        // A round after retirement is a plain zero without a flight behind it.
        final score = flight?.groupScore ?? (retired ? 0.0 : null);
        cells[round] = StandingsCell(
          score: score,
          dropped: standing.droppedRounds.contains(round),
          detail: detailsOfRound?[pilot.participationId],
        );
        reviewOpen =
            reviewOpen ||
            (facts.inReviewByRound[round]?.contains(pilot.participationId) ??
                false);
      }
      rows.add(
        StandingsRow(
          place: standing.place,
          isTied: standing.isTied,
          pilot: pilot,
          total: standing.overallScore,
          raw: standing.rawTotal - standing.penaltyTotal,
          penalty: standing.penaltyTotal,
          percentage: top > 0 ? standing.overallScore / top * 100 : null,
          cells: cells,
          reviewOpen: reviewOpen,
        ),
      );
    }
    return StandingsTable._(
      rows: rows,
      options: options,
      rounds: rounds,
      hasPenalty: rows.any((row) => row.penalty > 0),
      hasTie: rows.any((row) => row.isTied),
      isF3j: facts.disciplineLabel == 'F3J',
    );
  }

  final List<StandingsRow> rows;
  final StandingsOptions options;
  final List<int> rounds;
  final bool hasPenalty;
  final bool hasTie;

  /// F3J records no launch height, so its detail lines are two.
  final bool isF3j;

  /// The Flight details labels, in line order.
  List<String> get detailLabels =>
      isF3j ? const ['Time', 'Landing'] : const ['Time', 'Landing', 'Height'];

  /// The lines under a round score: time, landing points, launch height. A
  /// part that was not recorded is `—`, which is not 0.
  List<String> detailLines(FlightDetail? detail) {
    final lines = [
      if (detail?.seconds case final seconds?)
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'
      else
        '—',
      if (detail?.landing case final landing?)
        landing == landing.roundToDouble()
            ? landing.toStringAsFixed(0)
            : landing.toStringAsFixed(1)
      else
        '—',
      if (detail?.height case final height?) '${height}m' else '—',
    ];
    return lines.take(detailLabels.length).toList();
  }
}

/// How the sheet writes numbers: scores with the contest's decimals and
/// thousands separators, a zero round score as a plain `0`.
class StandingsFormat {
  StandingsFormat(this.decimals)
    : _number = NumberFormat(
        decimals == 0 ? '#,##0' : '#,##0.${'0' * decimals}',
        'en_US',
      );

  final int decimals;
  final NumberFormat _number;

  /// A total, raw score or round score with the contest's decimals.
  String score(double value) => _number.format(value);

  /// A round score: a plain 0 for zero.
  String round(double value) => value == 0 ? '0' : score(value);

  /// A penalty as a deduction: "−100.0".
  String penalty(double value) => '−${score(value)}';

  /// A percentage with one decimal: "97.4%".
  String percentage(double? value) =>
      value == null ? '—' : '${value.toStringAsFixed(1)}%';
}
