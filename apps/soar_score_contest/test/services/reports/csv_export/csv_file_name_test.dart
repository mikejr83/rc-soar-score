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

  test('uses the same safety logic as the PDF file name', () {
    expect(FileName.named('Overall Results – Gator Cup', 'csv'),
        csvFileName('Overall Results', 'Gator Cup'));
  });
}
