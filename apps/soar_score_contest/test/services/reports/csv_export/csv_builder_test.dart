import 'package:flutter_test/flutter_test.dart';
import 'package:soar_score_contest/services/reports/csv_export/csv_builder.dart';

void main() {
  final builder = const CsvBuilder();

  test('joins cells with commas and rows with CRLF', () {
    expect(builder.build(const [
      ['a', 'b'],
      ['c', 'd'],
    ]), 'a,b\r\nc,d\r\n');
  });

  test('a null cell is empty, distinct from a real value', () {
    expect(builder.build(const [[null, 'x']]), ',x\r\n');
    expect(builder.build(const [['', 'x']]), ',x\r\n');
  });

  test('a comma in a cell is quoted', () {
    expect(builder.build(const [['a,b']]), '"a,b"\r\n');
  });

  test('a quote in a cell is quoted and doubled', () {
    expect(builder.build(const [['say "hi"']]), '"say ""hi"""\r\n');
  });

  test('a newline in a cell is quoted', () {
    expect(builder.build(const [['a\nb']]), '"a\nb"\r\n');
  });

  test('an empty document is empty', () {
    expect(builder.build(const []), '');
  });
}
