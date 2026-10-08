/// Friendly names for groups of IANA zones, after the Unicode CLDR metazone
/// names. Zones not listed here are labelled by city and area only.
abstract final class ZoneNames {
  /// The friendly name for [zoneId], or null when none is defined.
  static String? forZone(String zoneId) => _byZone[zoneId];

  static const Map<String, List<String>> _groups = {
    'Eastern Time (US & Canada)': [
      'America/New_York',
      'America/Detroit',
      'America/Toronto',
      'America/Indiana/Indianapolis',
      'America/Kentucky/Louisville',
    ],
    'Central Time (US & Canada)': [
      'America/Chicago',
      'America/Winnipeg',
      'America/Menominee',
    ],
    'Mountain Time (US & Canada)': [
      'America/Denver',
      'America/Edmonton',
      'America/Boise',
    ],
    'Mountain Time, no daylight saving (Arizona)': ['America/Phoenix'],
    'Pacific Time (US & Canada)': ['America/Los_Angeles', 'America/Vancouver'],
    'Alaska Time': ['America/Anchorage', 'America/Juneau'],
    'Hawaii Time': ['Pacific/Honolulu'],
    'Atlantic Time (Canada)': ['America/Halifax'],
    'Newfoundland Time': ['America/St_Johns'],
    'Greenwich Mean Time': [
      'Europe/London',
      'Europe/Dublin',
      'Atlantic/Reykjavik',
    ],
    'Western European Time': ['Europe/Lisbon', 'Atlantic/Canary'],
    'Central European Time': [
      'Europe/Amsterdam',
      'Europe/Belgrade',
      'Europe/Berlin',
      'Europe/Brussels',
      'Europe/Budapest',
      'Europe/Copenhagen',
      'Europe/Madrid',
      'Europe/Oslo',
      'Europe/Paris',
      'Europe/Prague',
      'Europe/Rome',
      'Europe/Stockholm',
      'Europe/Vienna',
      'Europe/Warsaw',
      'Europe/Zurich',
    ],
    'Eastern European Time': [
      'Europe/Athens',
      'Europe/Bucharest',
      'Europe/Helsinki',
      'Europe/Kyiv',
      'Europe/Sofia',
    ],
    'Moscow Time': ['Europe/Moscow'],
    'South Africa Standard Time': ['Africa/Johannesburg'],
    'China Standard Time': ['Asia/Shanghai'],
    'Japan Standard Time': ['Asia/Tokyo'],
    'Korea Standard Time': ['Asia/Seoul'],
    'India Standard Time': ['Asia/Kolkata'],
    'Western Australia Time': ['Australia/Perth'],
    'Central Australia Time': ['Australia/Adelaide', 'Australia/Darwin'],
    'Eastern Australia Time': [
      'Australia/Sydney',
      'Australia/Melbourne',
      'Australia/Hobart',
      'Australia/Brisbane',
    ],
    'New Zealand Time': ['Pacific/Auckland'],
    'Coordinated Universal Time': ['UTC', 'Etc/UTC'],
  };

  static final Map<String, String> _byZone = {
    for (final group in _groups.entries)
      for (final zone in group.value) zone: group.key,
  };
}
