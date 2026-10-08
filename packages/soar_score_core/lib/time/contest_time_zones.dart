import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'zone_names.dart';

/// The IANA time zones a contest can be held in, with display labels.
///
/// Zone ids (`Europe/Rome`) are what gets stored; labels are for people.
/// The bundled database works offline and on web, and covers daylight-saving
/// rules through 2037.
abstract final class ContestTimeZones {
  static const String utc = 'UTC';

  static bool _initialized = false;
  static List<String>? _ids;

  /// Loads the zone database; safe to call repeatedly.
  static void ensureInitialized() {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    _initialized = true;
  }

  /// Every zone id, sorted, including [utc].
  static List<String> get ids {
    ensureInitialized();
    return _ids ??= [
      utc,
      ...tz.timeZoneDatabase.locations.keys.where(_isOffered),
    ]..sort();
  }

  /// Whether [zoneId] names a zone in the database.
  static bool isValid(String zoneId) {
    ensureInitialized();
    return zoneId == utc || tz.timeZoneDatabase.locations.containsKey(zoneId);
  }

  /// The location for [zoneId]; throws [ArgumentError] when it is unknown.
  static tz.Location location(String zoneId) {
    ensureInitialized();
    // The database names UTC `Etc/UTC`; contests store plain `UTC`.
    final found =
        tz.timeZoneDatabase.locations[zoneId == utc ? 'Etc/UTC' : zoneId];
    if (found == null) {
      throw ArgumentError.value(zoneId, 'zoneId', 'Unknown time zone');
    }
    return found;
  }

  /// The UTC offset of [zoneId] at [at] (default now), like `UTC+02:00`.
  static String offsetLabel(String zoneId, {DateTime? at}) {
    final instant = (at ?? DateTime.now()).toUtc();
    final offset = tz.TZDateTime.from(instant, location(zoneId)).timeZoneOffset;
    final minutes = offset.inMinutes.abs();
    final sign = offset.isNegative ? '-' : '+';
    final hh = (minutes ~/ 60).toString().padLeft(2, '0');
    final mm = (minutes % 60).toString().padLeft(2, '0');
    return 'UTC$sign$hh:$mm';
  }

  /// A readable label such as `Central European Time · Rome · UTC+02:00`,
  /// or `Bangkok · Asia · UTC+07:00` when no friendly name is defined.
  static String label(String zoneId, {DateTime? at}) {
    if (zoneId == utc) return 'Coordinated Universal Time · UTC+00:00';
    final parts = zoneId.split('/');
    final friendly = ZoneNames.forZone(zoneId);
    return [
      ?friendly,
      parts.last.replaceAll('_', ' '),
      if (friendly == null && parts.length > 1)
        parts.first.replaceAll('_', ' '),
      offsetLabel(zoneId, at: at),
    ].join(' · ');
  }

  /// The zones whose id or label contains every word of [query].
  static List<String> search(String query, {DateTime? at}) {
    final words = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return ids;
    return [
      for (final id in ids)
        if (_matches(id, words, at)) id,
    ];
  }

  static bool _matches(String id, List<String> words, DateTime? at) {
    final haystack = '${id.replaceAll('_', ' ')} ${label(id, at: at)}'
        .toLowerCase();
    return words.every(haystack.contains);
  }

  // Skip the legacy aliases and fixed-offset Etc/ entries; they only add noise.
  static bool _isOffered(String id) =>
      (id.contains('/') &&
      !id.startsWith('Etc/') &&
      !id.startsWith('SystemV/') &&
      !id.startsWith('US/') &&
      !id.startsWith('Canada/') &&
      !id.startsWith('Brazil/') &&
      !id.startsWith('Chile/') &&
      !id.startsWith('Mexico/'));
}
