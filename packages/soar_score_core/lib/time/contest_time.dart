import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import 'contest_time_zones.dart';

/// Converts stored UTC instants to a contest's own time zone.
///
/// Everything pilots see during a contest should use the contest's zone, never
/// the viewer's device or profile zone.
abstract final class ContestTime {
  /// [utc] as wall-clock time in [zoneId], with that zone's rules for the date.
  static tz.TZDateTime inZone(DateTime utc, String zoneId) =>
      tz.TZDateTime.from(utc.toUtc(), ContestTimeZones.location(zoneId));

  /// `2026-10-08 14:31 CEST` for [utc] in [zoneId].
  ///
  /// With a [locale] (a BCP 47 tag such as `en-GB`) the date and time follow
  /// that locale's layout instead, for times shown to the director:
  /// `08/10/2026 14:31 CEST`. Pilot-facing callers pass none. A locale other
  /// than `en-US` needs its date symbols loaded first with
  /// `initializeDateFormatting` from `package:intl/date_symbol_data_local.dart`.
  static String format(DateTime utc, String zoneId, {String? locale}) {
    final t = inZone(utc, zoneId);
    if (locale != null) {
      final tag = Intl.canonicalizedLocale(locale);
      return '${DateFormat.yMd(tag).format(t)} ${DateFormat.Hm(tag).format(t)} '
          '${t.timeZoneName}';
    }
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year.toString().padLeft(4, '0')}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)} ${t.timeZoneName}';
  }
}
