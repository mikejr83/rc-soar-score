import 'package:soar_score_core/soar_score_core.dart';

/// The ways the contest's current configuration differs from the settings a
/// matrix was drawn with. A difference never alters the matrix.
abstract final class ConfigDrift {
  /// One sentence per difference, e.g. "Team protection is now Off (drawn
  /// with On)."; empty when nothing differs or the options are unknown.
  static List<String> differences({
    required MatrixRevision revision,
    required CoreOptions? options,
  }) {
    if (options == null) {
      return const [];
    }
    final drawn = revision.drawConfig;
    final found = <String>[];

    void compare(String label, String now, String? then) {
      if (then != null && then != now) {
        found.add('$label is now $now (drawn with $then).');
      }
    }

    final protection = drawn['team_protection'];
    compare(
      'Team protection',
      options.teamProtection ? 'On' : 'Off',
      protection is bool ? (protection ? 'On' : 'Off') : null,
    );
    compare(
      'Draw mode',
      drawModeText(options.drawMode),
      _drawMode(drawn['configured_draw_mode']),
    );
    compare(
      'Lane mode',
      laneModeText(options.laneMode),
      _laneMode(drawn['lane_mode']),
    );
    final preliminary = options.preliminaryRounds;
    if (options.drawMode == DrawMode.seededManOnMan && preliminary != null) {
      final rounds = revision.lastRound - revision.firstRound + 1;
      compare('Preliminary rounds', '$preliminary', '$rounds');
    }
    return found;
  }

  static String drawModeText(DrawMode mode) =>
      mode == DrawMode.seededManOnMan ? 'Seeded Man on Man' : 'Man on Man';

  static String laneModeText(LaneMode mode) =>
      mode == LaneMode.random ? 'Random' : 'None';

  static String? _drawMode(Object? json) {
    for (final mode in DrawMode.values) {
      if (mode.json == json) {
        return drawModeText(mode);
      }
    }
    return null;
  }

  static String? _laneMode(Object? json) {
    for (final mode in LaneMode.values) {
      if (mode.json == json) {
        return laneModeText(mode);
      }
    }
    return null;
  }
}
