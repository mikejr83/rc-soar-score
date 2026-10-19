/// The locales the apps ship translations for (ADR 0004).
///
/// Alpha ships `en-US` only. A locale is added here once its translation is
/// complete enough to offer.
abstract final class SupportedLocales {
  static const String defaultLocale = 'en-US';

  /// Every locale a preference can name, as BCP 47 tags.
  static const List<String> ids = [defaultLocale];

  static bool isSupported(String locale) => ids.contains(locale);
}
