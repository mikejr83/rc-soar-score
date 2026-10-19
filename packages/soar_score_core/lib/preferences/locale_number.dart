import 'package:intl/intl.dart';

/// Numbers written the way a locale writes them, for text shown to the
/// director (`1,234.5` in en-US, `1.234,5` in German). Scores and other
/// pilot-facing values keep their fixed format.
abstract final class LocaleNumber {
  /// [value] with [locale]'s separators and at most [maxFractionDigits]
  /// decimals. A locale other than `en-US` needs its number symbols loaded
  /// first with `initializeDateFormatting` from
  /// `package:intl/date_symbol_data_local.dart`.
  static String decimal(
    num value, {
    required String locale,
    int maxFractionDigits = 2,
  }) {
    final format = NumberFormat.decimalPattern(Intl.canonicalizedLocale(locale))
      ..maximumFractionDigits = maxFractionDigits;
    return format.format(value);
  }
}
