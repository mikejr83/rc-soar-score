import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/viewer/report_spec.dart';

import '../../../support/scoring_sheet_support.dart';

void main() {
  test('shows every drawn round with the usual columns by default', () {
    final options = sheetOptions();
    expect(options.rounds, [1, 2]);
    expect(options.range.isAll, isTrue);
    expect(options.check(), ReportCheck.ok);
    expect(options.clubChosen, isFalse);
    expect(options.validated, isTrue);
    expect(options.includeRetired, isFalse);
    expect(options.prefillChosen, isFalse);
    expect(options.summary, 'All rounds');
  });

  test('a range is inclusive and the upper bound stops at the last round', () {
    expect(sheetOptions({'from': '2', 'to': '2'}).rounds, [2]);
    expect(sheetOptions({'to': '9'}).rounds, [1, 2]);
    expect(sheetOptions({'from': '2', 'to': '2'}).summary, 'Round 2');
  });

  test('a lower bound above the upper bound is invalid', () {
    expect(
      sheetOptions({'from': '2', 'to': '1'}).check(),
      isA<ReportInvalid>(),
    );
  });

  test('a range of undrawn rounds is empty, not invalid', () {
    final check = sheetOptions({'from': '5', 'to': '6'}).check();
    expect(check, isA<ReportEmpty>());
    expect((check as ReportEmpty).title, 'No drawn rounds in this range');
  });

  test('the columns follow the switches', () {
    final options = sheetOptions({'club': '1', 'val': '0'});
    expect(options.showClub, isTrue);
    expect(options.validated, isFalse);
  });

  test('Pre-fill needs a score; the choice is kept until there is one', () {
    final options = sheetOptions({'pre': '1'});
    expect(options.prefillChosen, isTrue);
    expect(options.prefillAvailable, isFalse);
    expect(options.prefill, isFalse);
  });

  test('retired pilots are left out unless asked for', () {
    expect(sheetOptions({'ret': '1'}).includeRetired, isTrue);
    expect(sheetOptions({'ret': '0'}).includeRetired, isFalse);
  });
}
