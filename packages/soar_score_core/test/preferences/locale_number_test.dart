import 'package:intl/date_symbol_data_local.dart';
import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() => initializeDateFormatting('de'));

  test('en-US uses a comma for thousands and a point for decimals', () {
    expect(LocaleNumber.decimal(1234.5, locale: 'en-US'), '1,234.5');
  });

  test('German swaps the separators', () {
    expect(LocaleNumber.decimal(1234.5, locale: 'de'), '1.234,5');
  });

  test('the decimals are capped', () {
    expect(
      LocaleNumber.decimal(1.23456, locale: 'en-US', maxFractionDigits: 1),
      '1.2',
    );
  });
}
