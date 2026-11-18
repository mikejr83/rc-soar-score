import 'package:flutter_test/flutter_test.dart';

import 'package:soar_score_contest/services/reports/csv_export/save_csv_native.dart';
import 'package:soar_score_contest/services/reports/csv_export/score_export_error.dart';

/// A predicate that reports which of [existing] paths "exist".
bool Function(String path) existsIn(Set<String> existing) =>
    (String path) => existing.contains(path);

void main() {
  test('a path that already has the extension is kept', () {
    expect(
      finalSavePath('C:\\a\\scores.csv', 'csv', exists: existsIn({})),
      'C:\\a\\scores.csv',
    );
    // A match on the existing file does not refuse: the dialog confirmed it.
    expect(
      finalSavePath(
        'C:\\a\\scores.csv',
        'csv',
        exists: existsIn({'C:\\a\\scores.csv'}),
      ),
      'C:\\a\\scores.csv',
    );
  });

  test('the extension is appended when the name lacks it', () {
    expect(
      finalSavePath('C:\\a\\scores', 'csv', exists: existsIn({})),
      'C:\\a\\scores.csv',
    );
  });

  test('an existing file is not overwritten when the extension is appended', () {
    // The dialog confirmed "scores.txt" (which does not exist); appending .csv
    // changes the target to an existing file, so refuse rather than truncate.
    expect(
      () => finalSavePath(
        'C:\\a\\scores.txt',
        'csv',
        exists: existsIn({'C:\\a\\scores.txt.csv'}),
      ),
      throwsA(isA<ScoreExportError>()),
    );
  });

  test('trailing dots are stripped before appending', () {
    expect(
      finalSavePath('C:\\a\\scores.', 'csv', exists: existsIn({})),
      'C:\\a\\scores.csv',
    );
  });

  test('the extension match is case-insensitive', () {
    expect(
      finalSavePath('C:\\a\\scores.CSV', 'csv', exists: existsIn({})),
      'C:\\a\\scores.CSV',
    );
  });

  test('a non-csv extension is honoured', () {
    expect(
      finalSavePath('C:\\a\\scores', 'gsx', exists: existsIn({})),
      'C:\\a\\scores.gsx',
    );
    expect(
      () => finalSavePath(
        'C:\\a\\scores',
        'gsx',
        exists: existsIn({'C:\\a\\scores.gsx'}),
      ),
      throwsA(isA<ScoreExportError>()),
    );
  });
}
