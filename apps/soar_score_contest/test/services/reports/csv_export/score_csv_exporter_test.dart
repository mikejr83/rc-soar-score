import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'package:soar_score_contest/services/reports/csv_export/flight_details_format.dart';
import 'package:soar_score_contest/services/reports/csv_export/overall_results_format.dart';
import 'package:soar_score_contest/services/reports/csv_export/score_csv_exporter.dart';
import 'package:soar_score_contest/services/reports/csv_export/score_export_error.dart';
import 'package:soar_score_contest/services/reports/csv_export/score_export_options.dart';
import 'package:soar_score_contest/services/reports/csv_export/score_export_source.dart';
import 'package:soar_score_contest/services/reports/report_pilot.dart';

final _bo = ReportPilot(
  participationId: Id.parse('019c0000-0000-7000-8000-000000000012'),
  firstName: 'Bo',
  lastName: 'Ray',
);

const _options = ScoreExportOptions(
  from: 1,
  requestedTo: 2,
  to: 2,
  lastShown: 2,
  rounds: [1, 2],
  percentage: false,
  raw: false,
  team: false,
  number: false,
  pilotClass: false,
);

ScoreExportSource source() => ScoreExportSource(
  contestName: 'Gator Cup',
  decimalPlaces: 1,
  rounds: const [1, 2],
  standings: [
    ExportStandingsRow(
      place: 1,
      pilot: _bo,
      total: 1750,
      raw: 1750,
      penalty: 0,
      percentage: 100,
      cells: const {},
    ),
  ],
  flights: const [],
);

void main() {
  test('exportCsv builds the format rows with a BOM, header and CRLF', () {
    final exporter = ScoreCsvExporter(saveFile: (name, csv) async => null);
    final csv = exporter.exportCsv(
      source(),
      const OverallResultsFormat(_options),
    );
    // A UTF-8 BOM leads the file so Excel reads it as UTF-8.
    expect(csv, startsWith('\uFEFFRank,Pilot,Total,R1,R2\r\n'));
    expect(csv, endsWith('\r\n'));
  });

  test('a format that writes no BOM omits it', () {
    final exporter = ScoreCsvExporter(saveFile: (name, csv) async => null);
    final csv = exporter.exportCsv(
      source(),
      const OverallResultsFormat(_options, writeBom: false),
    );
    expect(csv, startsWith('Rank,Pilot,Total,R1,R2\r\n'));
  });

  test(
    'saveCsv names the file from the report and contest and saves it',
    () async {
      String? name;
      String? saved;
      final exporter = ScoreCsvExporter(
        saveFile: (fileName, csv) async {
          name = fileName;
          saved = csv;
          return fileName;
        },
      );
      final result = await exporter.saveCsv(
        source(),
        const FlightDetailsFormat(_options),
        reportName: 'Flight Details',
      );
      expect(name, 'Flight Details – Gator Cup.csv');
      expect(result, 'Flight Details – Gator Cup.csv');
      expect(saved, startsWith('\uFEFFPilot,'));
    },
  );

  test('a cancelled save is reported as null', () async {
    final exporter = ScoreCsvExporter(saveFile: (name, csv) async => null);
    expect(
      await exporter.saveCsv(
        source(),
        const FlightDetailsFormat(_options),
        reportName: 'X',
      ),
      isNull,
    );
  });

  test('a failed save throws a ScoreExportError, not null', () async {
    final exporter = ScoreCsvExporter(
      saveFile: (name, csv) async => throw Exception('disk full'),
    );
    expect(
      () => exporter.saveCsv(
        source(),
        const FlightDetailsFormat(_options),
        reportName: 'X',
      ),
      throwsA(isA<ScoreExportError>()),
    );
  });
}
