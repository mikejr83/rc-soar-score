import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'package:soar_score_contest/services/reports/csv_export/flight_details_format.dart';
import 'package:soar_score_contest/services/reports/csv_export/overall_results_format.dart';
import 'package:soar_score_contest/services/reports/csv_export/score_export_options.dart';
import 'package:soar_score_contest/services/reports/csv_export/score_export_source.dart';
import 'package:soar_score_contest/services/reports/report_pilot.dart';

final _ann = ReportPilot(
  participationId: Id.parse('019c0000-0000-7000-8000-000000000011'),
  firstName: 'Ann',
  lastName: 'Lee',
);
final _bo = ReportPilot(
  participationId: Id.parse('019c0000-0000-7000-8000-000000000012'),
  firstName: 'Bo',
  lastName: 'Ray',
);

ScoreExportOptions options({
  bool percentage = true,
  bool raw = false,
  bool team = false,
  bool number = false,
  bool pilotClass = false,
}) => ScoreExportOptions(
  from: 1,
  to: 2,
  rounds: [1, 2],
  provisional: false,
  percentage: percentage,
  raw: raw,
  team: team,
  number: number,
  pilotClass: pilotClass,
  details: false,
);

ScoreExportSource source({
  DisciplineType? discipline = DisciplineType.f5j,
  List<ExportStandingsRow> standings = const [],
  List<ExportFlightRow> flights = const [],
  int decimals = 1,
}) => ScoreExportSource(
  contestName: 'Cup',
  decimalPlaces: decimals,
  discipline: discipline,
  rounds: const [1, 2],
  standings: standings,
  flights: flights,
);

int col(List<List<String?>> rows, String name) => rows.first.indexOf(name);

void main() {
  group('Overall Results', () {
    final standings = [
      ExportStandingsRow(
        place: 1,
        pilot: _bo,
        total: 1750,
        raw: 1750,
        penalty: 0,
        percentage: 100,
        cells: {1: const ExportStandingsCell(score: 800), 2: const ExportStandingsCell(score: 950)},
      ),
      ExportStandingsRow(
        place: 2,
        pilot: _ann,
        total: 900,
        raw: 1400,
        penalty: 50,
        percentage: 51.4285,
        cells: {
          1: const ExportStandingsCell(score: 900),
          2: const ExportStandingsCell(score: 500, dropped: true),
        },
      ),
    ];

    test('header and rows with the default options', () {
      final rows = OverallResultsFormat(options()).build(source(standings: standings));
      expect(rows.first, ['Rank', 'Pilot', 'Total', 'Pct', 'R1', 'R2', 'Penalty']);
      expect(rows[1], ['1', 'Ray, Bo', '1750.0', '100.0', '800.0', '950.0', '0.0']);
      // The dropped round keeps its value, unmarked.
      expect(rows[2], ['2', 'Lee, Ann', '900.0', '51.4', '900.0', '500.0', '50.0']);
    });

    test('optional columns appear only when on', () {
      final rows = OverallResultsFormat(
        options(raw: true, number: true),
      ).build(source(
        standings: [
          ExportStandingsRow(
            place: 1,
            pilot: _bo,
            total: 1750,
            raw: 1750,
            penalty: 0,
            percentage: 100,
            cells: {
              1: const ExportStandingsCell(score: 800),
              2: const ExportStandingsCell(score: 950),
            },
          ),
        ],
      ));
      expect(rows.first, ['Rank', 'Pilot', 'Total', 'Pct', 'Raw', 'No.', 'R1', 'R2']);
    });

    test('the penalty column is omitted when no pilot has a deduction', () {
      final rows = OverallResultsFormat(options()).build(source(
        standings: [
          ExportStandingsRow(
            place: 1,
            pilot: _bo,
            total: 1750,
            raw: 1750,
            penalty: 0,
            percentage: 100,
            cells: {
              1: const ExportStandingsCell(score: 800),
              2: const ExportStandingsCell(score: 950),
            },
          ),
        ],
      ));
      expect(rows.first.last, isNot('Penalty'));
      expect(rows[1].last, '950.0');
    });

    test('a missing round score is an empty cell', () {
      final rows = OverallResultsFormat(options()).build(source(
        standings: [
          ExportStandingsRow(
            place: 1,
            pilot: _bo,
            total: 800,
            raw: 800,
            penalty: 0,
            percentage: 100,
            cells: {1: const ExportStandingsCell(score: 800), 2: const ExportStandingsCell()},
          ),
        ],
      ));
      expect(rows[1].last, null);
    });

    test('numbers use the contest decimals', () {
      final rows = OverallResultsFormat(options()).build(source(
        standings: [
          ExportStandingsRow(
            place: 1,
            pilot: _bo,
            total: 1750,
            raw: 1750,
            penalty: 0,
            percentage: 100,
            cells: {
              1: const ExportStandingsCell(score: 800),
              2: const ExportStandingsCell(score: 950),
            },
          ),
        ],
        decimals: 2,
      ));
      expect(rows[1][2], '1750.00');
    });
  });

  group('Flight Details', () {
    final flights = [
      ExportFlightRow(
        pilot: _bo,
        round: 1,
        group: 'A',
        seconds: 592,
        height: 105,
        landing: 50,
        raw: 800,
        roundScore: 800,
        selected: true,
        place: 1,
        total: 1750,
      ),
      ExportFlightRow(
        pilot: _ann,
        round: 2,
        group: 'B',
        seconds: 590,
        landing: 45,
        raw: 650,
        flightPenalty: 10,
        cumulativePenalty: 10,
        roundScore: 650,
        selected: true,
        place: 2,
        total: 900,
      ),
    ];

    test('header with the default options and F5J height', () {
      final rows = FlightDetailsFormat(options()).build(source(flights: flights));
      expect(
        rows.first,
        [
          'Pilot', 'Round', 'Group', 'Time', 'Height', 'Landing', 'Raw',
          'Flight penalty', 'Cumulative penalty', 'Round score', 'Selected', 'Place', 'Total',
        ],
      );
      expect(
        rows[1],
        ['Ray, Bo', '1', 'A', '592', '105', '50.0', '800.0', null, null, '800.0', 'Yes', '1', '1750.0'],
      );
    });

    test('F3J omits the height column', () {
      final rows = FlightDetailsFormat(options()).build(source(
        discipline: DisciplineType.f3j,
        flights: flights,
      ));
      expect(rows.first.contains('Height'), isFalse);
      expect(rows[1], ['Ray, Bo', '1', 'A', '592', '50.0', '800.0', null, null, '800.0', 'Yes', '1', '1750.0']);
    });

    test('optional identity columns appear only when on', () {
      final rows = FlightDetailsFormat(options(number: true, team: true)).build(
        source(flights: [
          ExportFlightRow(
            pilot: ReportPilot(
              participationId: _bo.participationId,
              firstName: 'Bo',
              lastName: 'Ray',
              number: 2,
              team: 'Hawks',
            ),
            round: 1,
            group: 'A',
            raw: 800,
            roundScore: 800,
            selected: true,
          ),
        ]),
      );
      expect(rows.first.take(5).toList(), ['Pilot', 'No.', 'Team', 'Round', 'Group']);
    });

    test('a non-selected flight is marked No', () {
      final rows = FlightDetailsFormat(options()).build(source(
        flights: [
          ExportFlightRow(
            pilot: _bo,
            round: 1,
            group: 'A',
            raw: 800,
            roundScore: 800,
            selected: false,
          ),
        ],
      ));
      expect(rows[1][col(rows, 'Selected')], 'No');
    });

    test('a missing value is an empty (null) cell', () {
      final rows = FlightDetailsFormat(options()).build(source(
        flights: [
          ExportFlightRow(
            pilot: _bo,
            round: 1,
            group: 'A',
            raw: 800,
            roundScore: 800,
            selected: true,
          ),
        ],
      ));
      expect(rows[1][col(rows, 'Time')], null);
      expect(rows[1][col(rows, 'Landing')], null);
    });
  });
}
