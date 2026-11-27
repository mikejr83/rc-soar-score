import 'supported_locales.dart';

/// One country the resolver knows: its ISO 3166-1 alpha-2 [code], the names
/// and abbreviations people type for it, and the single locale that fits it.
///
/// [locale] is null when a country has no one obvious locale (Belgium, Canada
/// and Switzerland are multilingual), so such a country resolves no locale
/// rather than a guess.
class _Country {
  const _Country(this.code, this.names, {this.locale});

  final String code;

  /// Lower-case spellings, including the IOC code GliderScore uses.
  final List<String> names;
  final String? locale;
}

const _countries = <_Country>[
  _Country('AR', ['argentina', 'arg'], locale: 'es-AR'),
  _Country('AU', ['australia', 'aus'], locale: 'en-AU'),
  _Country('AT', ['austria', 'aut'], locale: 'de-AT'),
  _Country('BE', ['belgium', 'bel']),
  _Country('BR', ['brazil', 'bra'], locale: 'pt-BR'),
  _Country('CA', ['canada', 'can']),
  _Country('CN', [
    'china',
    "people's republic of china",
    'chn',
  ], locale: 'zh-CN'),
  _Country('CZ', ['czech republic', 'czechia', 'cze'], locale: 'cs-CZ'),
  _Country('DK', ['denmark', 'den'], locale: 'da-DK'),
  _Country('FI', ['finland', 'fin'], locale: 'fi-FI'),
  _Country('FR', ['france', 'fra'], locale: 'fr-FR'),
  _Country('DE', ['germany', 'deutschland', 'ger'], locale: 'de-DE'),
  _Country('IT', ['italy', 'italia', 'ita'], locale: 'it-IT'),
  _Country('JP', ['japan', 'jpn'], locale: 'ja-JP'),
  _Country('MX', ['mexico', 'mex'], locale: 'es-MX'),
  _Country('NL', [
    'netherlands',
    'the netherlands',
    'holland',
    'ned',
  ], locale: 'nl-NL'),
  _Country('NZ', ['new zealand', 'nzl'], locale: 'en-NZ'),
  _Country('NO', ['norway', 'nor'], locale: 'nb-NO'),
  _Country('PL', ['poland', 'pol'], locale: 'pl-PL'),
  _Country('SK', ['slovakia', 'svk'], locale: 'sk-SK'),
  _Country('SI', ['slovenia', 'slo'], locale: 'sl-SI'),
  _Country('ZA', ['south africa', 'rsa'], locale: 'en-ZA'),
  _Country('ES', ['spain', 'españa', 'esp'], locale: 'es-ES'),
  _Country('SE', ['sweden', 'swe'], locale: 'sv-SE'),
  _Country('CH', ['switzerland', 'sui']),
  _Country('UA', ['ukraine', 'ukr'], locale: 'uk-UA'),
  _Country('GB', [
    'united kingdom',
    'uk',
    'u.k.',
    'gb',
    'great britain',
    'gbr',
  ], locale: 'en-GB'),
  _Country('US', [
    'united states',
    'united states of america',
    'us',
    'u.s.',
    'usa',
    'u.s.a.',
    'america',
  ], locale: 'en-US'),
];

final Map<String, _Country> _byName = {
  for (final country in _countries) ...{
    country.code.toLowerCase(): country,
    for (final name in country.names) name: country,
  },
};

/// Turns the free-text `country` of a contest or participant into something
/// the apps can use: an ISO country code, and from it a locale.
///
/// The text is free, so everything here answers null for what it does not
/// recognise and the caller falls through to its next choice. Only the
/// countries the product already serves are listed; add one by adding a row.
abstract final class CountryLocale {
  /// The ISO 3166-1 alpha-2 code for [country] (a name, an alias such as
  /// `usa` or `UK`, an IOC code such as `GER`, or the code itself), or null
  /// when [country] is empty or unknown.
  static String? codeFor(String? country) => _lookup(country)?.code;

  /// The supported locale for [country], or null when the country is
  /// unknown, has no single locale, or its locale is not one the apps ship.
  static String? localeFor(String? country) {
    final locale = _lookup(country)?.locale;
    return locale != null && SupportedLocales.isSupported(locale)
        ? locale
        : null;
  }

  /// The locale to write a message to a person in: their [preferred] locale
  /// when it is supported, else the one for the [country] of the contest,
  /// else [SupportedLocales.defaultLocale].
  static String resolve({String? preferred, String? country}) {
    if (preferred != null && SupportedLocales.isSupported(preferred)) {
      return preferred;
    }
    return localeFor(country) ?? SupportedLocales.defaultLocale;
  }

  static _Country? _lookup(String? country) {
    final key = country?.trim().toLowerCase();
    if (key == null || key.isEmpty) return null;
    return _byName[key.replaceAll(RegExp(r'\s+'), ' ')];
  }
}
