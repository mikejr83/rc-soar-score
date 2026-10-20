import 'package:flutter/widgets.dart';
import 'package:soar_score_core/soar_score_core.dart';

import '../../preferences_controller_provider.dart';

/// Writes a UTC instant as text.
typedef TimeText = String Function(DateTime utc);

/// Times shown to the director in the admin UI (last saved, last synced,
/// history), in the account's preferred time zone and locale.
///
/// Times pilots see (the next step, scoring progress, reports) use the
/// contest's own zone through [ContestTime] and never come through here.
abstract final class DirectorTime {
  /// The formatter for the preferences in effect at [context]; widgets that
  /// call it rebuild when the preferences change.
  static TimeText of(BuildContext context) {
    final preferences = preferencesOf(context);
    return (utc) => format(
      utc,
      zoneId: preferences?.timeZone,
      locale: preferences?.localeTag,
    );
  }

  /// The clock-only formatter (`14:31`) for the preferences at [context].
  static TimeText clockOf(BuildContext context) {
    final preferences = preferencesOf(context);
    return (utc) => clock(
      utc,
      zoneId: preferences?.timeZone,
      locale: preferences?.localeTag,
    );
  }

  /// [utc] as `10/8/2026 14:31 CEST` (en-US layout) in [zoneId], or in the
  /// device's own zone without one. [locale] changes the layout; without it
  /// the en-US layout is used.
  static String format(DateTime utc, {String? zoneId, String? locale}) {
    final tag = locale ?? 'en-US';
    if (zoneId != null && ContestTimeZones.isValid(zoneId)) {
      return ContestTime.format(utc, zoneId, locale: tag);
    }
    final local = utc.toLocal();
    return ContestTime.formatWallClock(local, local.timeZoneName, locale: tag);
  }

  /// Just the time of day of [utc] (`14:31`), in the same zone as [format].
  static String clock(DateTime utc, {String? zoneId, String? locale}) {
    final wall = zoneId != null && ContestTimeZones.isValid(zoneId)
        ? ContestTime.inZone(utc, zoneId)
        : utc.toLocal();
    return ContestTime.formatClock(wall, locale: locale ?? 'en-US');
  }
}
