import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/csv_export/csv_file_name.dart';
import 'package:soar_score_contest/services/reports/file_name.dart';

void main() {
  test('names the file from the report and contest', () {
    expect(
      csvFileName('Overall Results', 'Gator Cup'),
      'Overall Results – Gator Cup.csv',
    );
  });

  test('a custom extension is kept', () {
    expect(
      csvFileName('GliderScore F5J', 'Gator Cup', extension: 'gsx'),
      'GliderScore F5J – Gator Cup.gsx',
    );
  });

  test('refused characters and long names are handled', () {
    expect(
      csvFileName('Draw A/B: "Cup"', 'Gator Cup'),
      'Draw A-B- -Cup- – Gator Cup.csv',
    );
    expect(csvFileName('', 'Cup'), '– Cup.csv');
    // The base is held to 120 characters (the contest name is cut off); the
    // ".csv" is on top.
    expect(csvFileName('x' * 300, 'Cup').length, 124);
  });

  test('a Windows reserved name is made safe', () {
    // The CSV base is always "{Report} – {Contest}", so a bare reserved word
    // is reached through the shared FileName (as the PDF printer's title can
    // be). The guard appends a dash to the reserved base.
    expect(FileName.named('con', 'csv'), 'con-.csv');
    expect(FileName.named('NUL', 'csv'), 'NUL-.csv');
    // And csvFileName routes through the same FileName logic.
    expect(
      FileName.named('Overall Results – Gator Cup', 'csv'),
      csvFileName('Overall Results', 'Gator Cup'),
    );
  });
}
