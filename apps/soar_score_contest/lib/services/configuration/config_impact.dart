/// What changing a configuration option does to work already done
/// (`plan/ui/contest-administration/contest-workspace.md`).
enum ConfigImpact {
  /// Nothing derived depends on it.
  none('No effect on the matrix or scores'),

  /// Derived scores and standings are recalculated.
  scores('Recalculates scores'),

  /// The drawn matrix no longer matches the options and has to be redrawn.
  matrix('Invalidates the matrix');

  const ConfigImpact(this.label);

  final String label;

  /// The impact of changing the core option [key].
  static ConfigImpact ofCoreOption(String key) => switch (key) {
    'teams_enabled' ||
    'team_pilot_count' ||
    'team_protection' ||
    'draw_mode' ||
    'preliminary_rounds' ||
    'lane_mode' ||
    'intended_total_rounds' => matrix,
    'group_score_mode' ||
    'rounding_mode' ||
    'decimal_places' ||
    'drop_after_rounds' ||
    'tiebreaker_enabled' => scores,
    _ => none,
  };
}
