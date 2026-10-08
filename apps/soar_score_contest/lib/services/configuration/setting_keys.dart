/// The keys of the settings on the configuration page.
///
/// Core options use their key in `plan/data-model/contest-options.md`; the
/// contest details and the landing table have their own; a discipline option
/// is its field key behind [disciplinePrefix]. [drops], [drop1] and [drop2]
/// together stand for `drop_after_rounds`.
abstract final class SettingKeys {
  static const name = 'name';
  static const start = 'start';
  static const end = 'end';
  static const host = 'host';
  static const city = 'city';
  static const state = 'state';
  static const country = 'country';

  static const disciplinePrefix = 'd_';
  static const landingTable = 'landing_table';

  static const groupScoreMode = 'group_score_mode';
  static const roundingMode = 'rounding_mode';
  static const decimalPlaces = 'decimal_places';
  static const drops = 'drops';
  static const drop1 = 'drop1';
  static const drop2 = 'drop2';
  static const tiebreaker = 'tiebreaker_enabled';
  static const teamPilotCount = 'team_pilot_count';

  static const teams = 'teams_enabled';
  static const roles = 'roles_enabled';
  static const classes = 'classes_enabled';
  static const models = 'models_enabled';
  static const participantNumbers = 'participant_numbers_enabled';

  static const drawMode = 'draw_mode';
  static const preliminaryRounds = 'preliminary_rounds';
  static const intendedTotalRounds = 'intended_total_rounds';
  static const teamProtection = 'team_protection';
  static const laneMode = 'lane_mode';

  static const publicUpdateMode = 'public_update_mode';
  static const reviewRequests = 'review_requests_enabled';

  /// The `draw_mode` values.
  static const seeded = 'SeededManOnMan';
  static const standard = 'StandardManOnMan';

  /// Changing these makes a drawn matrix out of date.
  static const matrixKeys = {
    teams,
    teamProtection,
    drawMode,
    preliminaryRounds,
    laneMode,
  };

  /// Besides [matrixKeys], the discipline options and the landing table,
  /// these are fixed once scoring has started.
  static const fixedWhenRunning = {roles, participantNumbers};

  /// The setting that shows each dependent one; the dependent is cleared when
  /// its parent hides it.
  static const parentOf = {
    teamPilotCount: teams,
    teamProtection: teams,
    preliminaryRounds: drawMode,
    intendedTotalRounds: drawMode,
    drop1: drops,
    drop2: drops,
  };

  static const timezone = 'timezone';

  static bool isDiscipline(String key) => key.startsWith(disciplinePrefix);
}
