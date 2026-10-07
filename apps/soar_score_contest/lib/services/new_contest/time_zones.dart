/// The IANA time zones offered by the New Contest wizard, and a best guess
/// at this device's.
///
/// Dart reports only the local zone's abbreviation (`EST`) or, on Windows,
/// its display name (`Eastern Standard Time`), so the device zone is matched
/// from those. A zone that can't be matched falls back to [utc]; the user
/// can always pick another.
abstract final class TimeZones {
  static const String utc = 'UTC';

  static const List<String> offered = [
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Phoenix',
    'America/Los_Angeles',
    'America/Anchorage',
    'Pacific/Honolulu',
    'America/Toronto',
    'America/Vancouver',
    'Europe/London',
    'Europe/Berlin',
    'Europe/Paris',
    'Europe/Helsinki',
    'Africa/Johannesburg',
    'Asia/Tokyo',
    'Australia/Perth',
    'Australia/Adelaide',
    'Australia/Sydney',
    'Pacific/Auckland',
    utc,
  ];

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

  /// The offered zone matching the local zone [name] (by default this
  /// device's), else [utc].
  static String device([String? name]) =>
      _byName[name ?? DateTime.now().timeZoneName] ?? utc;
}
