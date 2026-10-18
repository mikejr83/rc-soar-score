import 'package:soar_score_core/soar_score_core.dart';

import 'time_entry.dart';

/// One line that says what an official score holds, for the history view:
/// `9:00 · 200 m · Within 1 m · Late landing`.
abstract final class ScoreComponentsText {
  static String describe(
    Map<String, Object?> components, {
    List<LandingResult> landings = const [],
  }) {
    final parts = <String>[];
    final time = components['time_flown'];
    if (time is num) parts.add(TimeEntry.clock(time));
    final height = components['launch_height'];
    if (height is num) parts.add('${height.toInt()} m');
    final landing = components['landing'];
    if (landing is String) {
      final match = landings.where((l) => l.entryKey == landing).firstOrNull;
      parts.add(match?.displayValue ?? landing);
    }
    for (final (key, label) in const [
      ('late_landing', 'Late landing'),
      ('motor_restart', 'Motor restart'),
      ('out_of_bounds', 'Out of bounds'),
      ('no_altitude_recorded', 'No altitude recorded'),
    ]) {
      if (components[key] == true) parts.add(label);
    }
    final penalty = components['flight_penalty'];
    if (penalty is num && penalty > 0) parts.add('Penalty ${penalty.toInt()}');
    return parts.isEmpty ? 'Nothing entered' : parts.join(' · ');
  }
}
