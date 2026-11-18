import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'package:soar_score_contest/services/reports/csv_export/flight_details_format.dart';
import 'package:soar_score_contest/services/reports/csv_export/overall_results_format.dart';
import 'package:soar_score_contest/services/reports/csv_export/score_csv_exporter.dart';
import 'package:soar_score_contest/services/reports/csv_export/score_csv_format.dart';
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
  requestedTo: 2,
  to: 2,
  lastShown: 2,
  rounds: [1, 2],
  percentage: percentage,
  raw: raw,
  team: team,
  number: number,
  pilotClass: pilotClass,
);

ScoreExportSource source({
  List<ExportStandingsRow> standings = const [],
  List<ExportFlightRow> flights = const [],
  int decimals = 1,
}) => ScoreExportSource(
  contestName: 'Cup',
  decimalPlaces: decimals,
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
        cells: {
          1: const ExportStandingsCell(score: 800),
          2: const ExportStandingsCell(score: 950),
        },
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
      final rows = OverallResultsFormat(options())
          .build(source(standings: standings));
      expect(rows.first, [
        'Rank',
        'Pilot',
        'Total',
        'Pct',
        'R1',
        'R2',
        'Penalty deducted',
      ]);
      expect(rows[1], [
        '1',
        'Ray, Bo',
        '1750.0',
        '100.0',
        '800.0',
        '950.0',
        '0.0',
      ]);
      // The dropped round keeps its value with a * prefix.
      expect(rows[2], [
        '2',
        'Lee, Ann',
        '900.0',
        '51.4',
        '900.0',
        '*500.0',
        '50.0',
      ]);
    });

    test('optional columns appear only when on', () {
      final rows = OverallResultsFormat(options(raw: true, number: true)).build(
        source(
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
        ),
      );
      expect(rows.first, [
        'Rank',
        'Pilot',
        'Total',
        'Pct',
        'Raw',
        'No.',
        'R1',
        'R2',
      ]);
    });

    test('the penalty column is omitted when no pilot has a deduction', () {
      final rows = OverallResultsFormat(options()).build(
        source(
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
        ),
      );
      expect(rows.first.last, isNot('Penalty deducted'));
      expect(rows[1].last, '950.0');
    });

    test('a missing round score is an empty cell', () {
      final rows = OverallResultsFormat(options()).build(
        source(
          standings: [
            ExportStandingsRow(
              place: 1,
              pilot: _bo,
              total: 800,
              raw: 800,
              penalty: 0,
              percentage: 100,
              cells: {
                1: const ExportStandingsCell(score: 800),
                2: const ExportStandingsCell(),
              },
            ),
          ],
        ),
      );
      expect(rows[1].last, null);
    });

    test('numbers use the contest decimals', () {
      final rows = OverallResultsFormat(options()).build(
        source(
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
        ),
      );
      expect(rows[1][2], '1750.00');
    });

    test('text cells that start with a formula character are hardened', () {
      final rows = OverallResultsFormat(options(team: true, pilotClass: true))
          .build(
            source(
              standings: [
                ExportStandingsRow(
                  place: 1,
                  pilot: ReportPilot(
                    participationId: _bo.participationId,
                    // A pilot whose list name (surname, first) starts with a
                    // formula character.
                    firstName: 'Bo',
                    lastName: '@Ray',
                    team: '=SUM(A1)',
                    className: '-Open',
                  ),
                  total: 1750,
                  raw: 1750,
                  penalty: 0,
                  percentage: 100,
                  cells: const {},
                ),
              ],
            ),
          );
      expect(rows[1][col(rows, 'Pilot')], "'@Ray, Bo");
      expect(rows[1][col(rows, 'Team')], "'=SUM(A1)");
      expect(rows[1][col(rows, 'Class')], "'-Open");
    });

    test('a negative number stays a number, never prefixed', () {
      final rows = OverallResultsFormat(options()).build(
        source(
          standings: [
            ExportStandingsRow(
              place: 1,
              pilot: _bo,
              total: -5,
              raw: -5,
              penalty: 0,
              percentage: 0,
              cells: const {},
            ),
          ],
        ),
      );
      expect(rows[1][col(rows, 'Total')], '-5.0');
    });

    test('hardening is off for a format that wants raw text', () {
      final rows =
          OverallResultsFormat(
            options(team: true, pilotClass: true),
            hardenText: false,
          ).build(
            source(
              standings: [
                ExportStandingsRow(
                  place: 1,
                  pilot: ReportPilot(
                    participationId: _bo.participationId,
                    firstName: 'Bo',
                    lastName: '@Ray',
                    team: '=SUM(A1)',
                    className: '-Open',
                  ),
                  total: 1750,
                  raw: 1750,
                  penalty: 0,
                  percentage: 100,
                  cells: const {},
                ),
              ],
            ),
          );
      expect(rows[1][col(rows, 'Pilot')], '@Ray, Bo');
      expect(rows[1][col(rows, 'Team')], '=SUM(A1)');
      expect(rows[1][col(rows, 'Class')], '-Open');
    });

    test(
      'a BOM leads the file and a non-ASCII name with a comma is quoted',
      () {
        final exporter = ScoreCsvExporter(
          saveFile: (name, csv, {String? extension}) async => null,
        );
        final csv = exporter.exportCsv(
          source(
            standings: [
              ExportStandingsRow(
                place: 1,
                pilot: ReportPilot(
                  participationId: _bo.participationId,
                  firstName: 'José',
                  lastName: 'García, Jr.',
                ),
                total: 1750,
                raw: 1750,
                penalty: 0,
                percentage: 100,
                cells: const {},
              ),
            ],
          ),
          OverallResultsFormat(options()),
        );
        // The BOM is first; the pilot cell (with a comma) is quoted.
        expect(csv, startsWith('\uFEFFRank,Pilot'));
        expect(csv, contains('"García, Jr., José"'));
      },
    );
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

    test('header and rows with the default options', () {
      final rows = FlightDetailsFormat(options())
          .build(source(flights: flights));
      expect(rows.first, [
        'Pilot',
        'Round',
        'Group',
        'Time (s)',
        'Height (m)',
        'Landing',
        'Flight raw',
        'Flight penalty',
        'Cumulative penalty',
        'Round score',
        'Selected',
        'Place',
        'Total',
      ]);
      expect(rows[1], [
        'Ray, Bo',
        '1',
        'A',
        '592',
        '105',
        '50.0',
        '800.0',
        null,
        null,
        '800.0',
        'Yes',
        '1',
        '1750.0',
      ]);
    });

    test('the height column is always present, empty when not recorded', () {
      final rows = FlightDetailsFormat(options())
          .build(source(flights: flights));
      // The second flight recorded no height.
      expect(rows[1][col(rows, 'Height (m)')], '105');
      expect(rows[2][col(rows, 'Height (m)')], null);
    });

    test('optional identity columns appear only when on', () {
      final rows = FlightDetailsFormat(options(number: true, team: true)).build(
        source(
          flights: [
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
          ],
        ),
      );
      expect(rows.first.take(5).toList(), [
        'Pilot',
        'No.',
        'Team',
        'Round',
        'Group',
      ]);
    });

    test('a non-selected flight is marked No', () {
      final rows = FlightDetailsFormat(options()).build(
        source(
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
        ),
      );
      expect(rows[1][col(rows, 'Selected')], 'No');
    });

    test('a missing value is an empty (null) cell', () {
      final rows = FlightDetailsFormat(options()).build(
        source(
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
        ),
      );
      expect(rows[1][col(rows, 'Time (s)')], null);
      expect(rows[1][col(rows, 'Landing')], null);
    });

    test('text cells are hardened, including the pilot name', () {
      final rows = FlightDetailsFormat(options()).build(
        source(
          flights: [
            ExportFlightRow(
              pilot: ReportPilot(
                participationId: _bo.participationId,
                firstName: 'Bo',
                lastName: '@Ray',
              ),
              round: 1,
              group: 'A',
              raw: 800,
              roundScore: 800,
              selected: true,
            ),
          ],
        ),
      );
      expect(rows[1][col(rows, 'Pilot')], "'@Ray, Bo");
    });
  });

  group('harden', () {
    test('prefixes a formula or control starter', () {
      expect(ScoreCsvFormat.harden('=1+1'), "'=1+1");
      expect(ScoreCsvFormat.harden('+x'), "'+x");
      expect(ScoreCsvFormat.harden('-x'), "'-x");
      expect(ScoreCsvFormat.harden('@x'), "'@x");
      expect(ScoreCsvFormat.harden('\tx'), "'\tx");
      expect(ScoreCsvFormat.harden('\rx'), "'\rx");
    });

    test('leaves ordinary text alone', () {
      expect(ScoreCsvFormat.harden('Ray, Bo'), 'Ray, Bo');
      expect(ScoreCsvFormat.harden(''), '');
      expect(ScoreCsvFormat.harden('9:52'), '9:52');
    });
  });
}
