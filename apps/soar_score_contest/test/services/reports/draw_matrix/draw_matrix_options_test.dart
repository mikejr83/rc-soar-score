import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/draw_matrix/draw_matrix_options.dart';
import 'package:soar_score_contest/services/reports/viewer/report_spec.dart';

import '../../../support/draw_matrix_support.dart';

void main() {
  final facts = factsOfPage(drawnPage());

  DrawMatrixOptions of(Map<String, String> filters) => DrawMatrixOptions.of({
    ...DrawMatrixOptions.defaults(facts),
    ...filters,
  }, facts);

  test('shows every drawn round by default', () {
    final options = of({});
    expect(options.rounds, [1, 2]);
    expect(options.isAll, isTrue);
    expect(options.compact, isFalse);
    expect(options.additional, isFalse);
    expect(options.check(), ReportCheck.ok);
    expect(options.rangeMessage, 'All rounds.');
    expect(options.summary, 'All rounds');
  });

  test('a range is inclusive and says what it shows', () {
    final options = of({'from': '2', 'to': '2'});
    expect(options.rounds, [2]);
    expect(options.isAll, isFalse);
    expect(options.rangeMessage, 'Showing rounds 2 to 2 of 2.');
    expect(options.summary, 'Round 2');
  });

  test('a lower bound above the upper bound is invalid', () {
    final check = of({'from': '2', 'to': '1'}).check();
    expect(check, isA<ReportInvalid>());
  });

  test('a range of undrawn rounds is empty, not invalid', () {
    final check = of({'from': '5', 'to': '6'}).check();
    expect(check, isA<ReportEmpty>());
    check as ReportEmpty;
    expect(check.title, 'No drawn rounds in this range');
    expect(
      check.body,
      'Rounds 5–6 aren’t drawn. Only rounds 1 to 2 can be printed.',
    );
  });

  test('the upper bound is held to the last drawn round', () {
    final options = of({'to': '9'});
    expect(options.requestedTo, 9);
    expect(options.to, 2);
    expect(options.rounds, [1, 2]);
    expect(options.isAll, isTrue);
  });

  test('additional pilot info is off in compact mode but the choice stays', () {
    final on = of({'inf': '1', 'nat': '1'});
    expect(on.showClub, isTrue);
    expect(on.showFai, isTrue);
    expect(on.showNational, isTrue);

    final compact = of({'inf': '1', 'nat': '1', 'cmp': '1'});
    expect(compact.additionalAvailable, isFalse);
    expect(compact.additionalChosen, isTrue);
    expect(compact.additional, isFalse);
    expect(compact.showClub, isFalse);
    expect(compact.national, isTrue);
    expect(compact.summary, 'All rounds · Compact');
  });

  test('club and FAI ID start ticked, National ID does not', () {
    final options = of({'inf': '1'});
    expect(options.showClub, isTrue);
    expect(options.showFai, isTrue);
    expect(options.showNational, isFalse);
  });
}
