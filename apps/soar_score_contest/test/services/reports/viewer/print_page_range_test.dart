import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/viewer/print_page_range.dart';
import 'package:soar_score_contest/services/reports/viewer/report_view_params.dart';

void main() {
  group('PrintPageRange', () {
    test('blank means every page', () {
      expect(PrintPageRange.parse('', 3).pages, [1, 2, 3]);
      expect(PrintPageRange.parse('  ', 3).pages, [1, 2, 3]);
    });

    test('reads a page, a range and a list', () {
      expect(PrintPageRange.parse('1', 5).pages, [1]);
      expect(PrintPageRange.parse('2-4', 5).pages, [2, 3, 4]);
      expect(PrintPageRange.parse('1, 3-4', 5).pages, [1, 3, 4]);
      expect(PrintPageRange.parse('3,1,3', 5).pages, [1, 3]);
      expect(PrintPageRange.parse('2 – 3', 5).pages, [2, 3]);
    });

    test('a page outside the sheet or a backwards range is an error', () {
      for (final text in ['0', '6', '4-2', '1-9', 'a', '1-', '1;x']) {
        final range = PrintPageRange.parse(text, 5);
        expect(range.isValid, isFalse, reason: text);
        expect(range.pages, isEmpty, reason: text);
        expect(range.error, contains('1 to 5'), reason: text);
      }
    });

    test('a one-page sheet says so', () {
      expect(PrintPageRange.parse('2', 1).error, 'This sheet has one page.');
    });
  });

  test('the typed pages are kept in the URL', () {
    const params = ReportViewParams(printPages: '2-3');
    expect(params.toQuery()['pp'], '2-3');
    expect(ReportViewParams.fromQuery(params.toQuery()).printPages, '2-3');
    expect(const ReportViewParams().toQuery().containsKey('pp'), isFalse);
  });
}
