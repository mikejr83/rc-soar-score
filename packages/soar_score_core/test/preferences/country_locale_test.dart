import 'package:soar_score_core/soar_score_core.dart';
import 'package:test/test.dart';

void main() {
  group('CountryLocale.codeFor', () {
    test('reads names, aliases, IOC codes and codes', () {
      expect(CountryLocale.codeFor('United States'), 'US');
      expect(CountryLocale.codeFor(' usa '), 'US');
      expect(CountryLocale.codeFor('U.S.A.'), 'US');
      expect(CountryLocale.codeFor('UK'), 'GB');
      expect(CountryLocale.codeFor('Great  Britain'), 'GB');
      expect(CountryLocale.codeFor('GER'), 'DE');
      expect(CountryLocale.codeFor('Switzerland'), 'CH');
      expect(CountryLocale.codeFor('ca'), 'CA');
    });

    test('answers null for empty or unknown text', () {
      expect(CountryLocale.codeFor(null), isNull);
      expect(CountryLocale.codeFor('   '), isNull);
      expect(CountryLocale.codeFor('Atlantis'), isNull);
    });
  });

  group('CountryLocale.localeFor', () {
    test('answers only a locale the apps ship', () {
      expect(CountryLocale.localeFor('United States'), 'en-US');
      // Known country, but en-GB is not shipped.
      expect(CountryLocale.localeFor('United Kingdom'), isNull);
      // Multilingual: no single locale.
      expect(CountryLocale.localeFor('Canada'), isNull);
      expect(CountryLocale.localeFor('Atlantis'), isNull);
    });
  });

  group('CountryLocale.resolve', () {
    test('prefers the person, then the country, then the default', () {
      expect(
        CountryLocale.resolve(preferred: 'en-US', country: 'Germany'),
        'en-US',
      );
      expect(CountryLocale.resolve(country: 'United States'), 'en-US');
      expect(
        CountryLocale.resolve(preferred: 'xx-XX', country: 'Atlantis'),
        SupportedLocales.defaultLocale,
      );
      expect(CountryLocale.resolve(), SupportedLocales.defaultLocale);
    });
  });
}
