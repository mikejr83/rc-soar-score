import 'package:soar_score_core/soar_score_core.dart';

/// Picks the default IANA time zone for the New Contest wizard.
///
/// The zone list and labels live in [ContestTimeZones]. Dart reports only the
/// local zone's abbreviation (`EST`) or, on Windows, its display name
/// (`Eastern Standard Time`), so the device zone is matched from those, then
/// by abbreviation and offset against the zone database. A zone that can't be
/// matched falls back to [utc]; the user can always pick another.
abstract final class TimeZones {
  static const String utc = 'UTC';

  /// Countries with a single zone, by lower-case name, for the default.
  static const Map<String, String> _byCountry = {
    'italy': 'Europe/Rome',
    'spain': 'Europe/Madrid',
    'germany': 'Europe/Berlin',
    'france': 'Europe/Paris',
    'netherlands': 'Europe/Amsterdam',
    'switzerland': 'Europe/Zurich',
    'austria': 'Europe/Vienna',
    'poland': 'Europe/Warsaw',
    'united kingdom': 'Europe/London',
    'uk': 'Europe/London',
    'great britain': 'Europe/London',
    'china': 'Asia/Shanghai',
    'japan': 'Asia/Tokyo',
    'new zealand': 'Pacific/Auckland',
    'south africa': 'Africa/Johannesburg',
  };

  static const Map<String, String> _byName = {
    'EST': 'America/New_York',
    'EDT': 'America/New_York',
    'Eastern Standard Time': 'America/New_York',
    'Eastern Daylight Time': 'America/New_York',
    'CST': 'America/Chicago',
    'CDT': 'America/Chicago',
    'Central Standard Time': 'America/Chicago',
    'Central Daylight Time': 'America/Chicago',
    'MST': 'America/Denver',
    'MDT': 'America/Denver',
    'Mountain Standard Time': 'America/Denver',
    'Mountain Daylight Time': 'America/Denver',
    'US Mountain Standard Time': 'America/Phoenix',
    'PST': 'America/Los_Angeles',
    'PDT': 'America/Los_Angeles',
    'Pacific Standard Time': 'America/Los_Angeles',
    'Pacific Daylight Time': 'America/Los_Angeles',
    'AKST': 'America/Anchorage',
    'AKDT': 'America/Anchorage',
    'Alaskan Standard Time': 'America/Anchorage',
    'HST': 'Pacific/Honolulu',
    'Hawaiian Standard Time': 'Pacific/Honolulu',
    'GMT': 'Europe/London',
    'BST': 'Europe/London',
    'GMT Standard Time': 'Europe/London',
    'CET': 'Europe/Berlin',
    'CEST': 'Europe/Berlin',
    'W. Europe Standard Time': 'Europe/Berlin',
    'Romance Standard Time': 'Europe/Paris',
    'EET': 'Europe/Helsinki',
    'EEST': 'Europe/Helsinki',
    'FLE Standard Time': 'Europe/Helsinki',
    'SAST': 'Africa/Johannesburg',
    'South Africa Standard Time': 'Africa/Johannesburg',
    'JST': 'Asia/Tokyo',
    'Tokyo Standard Time': 'Asia/Tokyo',
    'AWST': 'Australia/Perth',
    'W. Australia Standard Time': 'Australia/Perth',
    'ACST': 'Australia/Adelaide',
    'ACDT': 'Australia/Adelaide',
    'Cen. Australia Standard Time': 'Australia/Adelaide',
    'AEST': 'Australia/Sydney',
    'AEDT': 'Australia/Sydney',
    'AUS Eastern Standard Time': 'Australia/Sydney',
    'NZST': 'Pacific/Auckland',
    'NZDT': 'Pacific/Auckland',
    'New Zealand Standard Time': 'Pacific/Auckland',
    'UTC': utc,
    'Coordinated Universal Time': utc,
  };

  /// The zone matching the local zone [name] (by default this device's),
  /// else [utc].
  static String device([String? name, Duration? offset]) {
    final clock = DateTime.now();
    final key = name ?? clock.timeZoneName;
    final named = _byName[key];
    if (named != null) return named;
    final wanted = offset ?? clock.timeZoneOffset;
    final now = clock.toUtc();
    for (final id in ContestTimeZones.ids) {
      final local = ContestTime.inZone(now, id);
      if (local.timeZoneName == key && local.timeZoneOffset == wanted) {
        return id;
      }
    }
    return utc;
  }

  /// The zone to use for a contest: the [chosen] one, else the single zone of
  /// [country] when we know it, else this device's.
  static String effective(String? chosen, String country) =>
      chosen ?? _byCountry[country.trim().toLowerCase()] ?? device();
}
