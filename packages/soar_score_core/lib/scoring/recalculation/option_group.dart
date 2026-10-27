/// The four kinds of contest setting, by what a change to them does.
///
/// See the table in `plan/data-model/contest-options.md`.
enum OptionGroup {
  /// Teams, roles, draw mode, preliminary rounds and lane mode.
  structural,

  /// The discipline's own field values and the landing table.
  scoringRules,

  /// Settings that change derived scores; every stored result goes stale.
  recalculating,

  /// Settings that change how results are shown, not what they are.
  presentation,
}

/// The group of each core option key. A key not listed here is treated as
/// [OptionGroup.recalculating], the safe choice, so a newer option never
/// leaves a stale result unmarked.
const Map<String, OptionGroup> coreOptionGroups = {
  'teams_enabled': OptionGroup.structural,
  'team_protection': OptionGroup.structural,
  'allow_back_to_back': OptionGroup.structural,
  'roles_enabled': OptionGroup.structural,
  'draw_mode': OptionGroup.structural,
  'preliminary_rounds': OptionGroup.structural,
  'lane_mode': OptionGroup.structural,
  'team_pilot_count': OptionGroup.recalculating,
  'group_score_mode': OptionGroup.recalculating,
  'rounding_mode': OptionGroup.recalculating,
  'decimal_places': OptionGroup.recalculating,
  'drop_after_rounds': OptionGroup.recalculating,
  'tiebreaker_enabled': OptionGroup.recalculating,
  'classes_enabled': OptionGroup.presentation,
  'models_enabled': OptionGroup.presentation,
  'participant_numbers_enabled': OptionGroup.presentation,
  'review_requests_enabled': OptionGroup.presentation,
  'public_update_mode': OptionGroup.presentation,
  'intended_total_rounds': OptionGroup.presentation,
};
