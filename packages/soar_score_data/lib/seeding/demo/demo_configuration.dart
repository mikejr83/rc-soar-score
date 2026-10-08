import 'package:soar_score_core/soar_score_core.dart' as core;

import 'demo_contest_plan.dart';

/// The contest configuration the demo gives a [DemoContestPlan]: the wizard's
/// defaults plus the options the plan turns on.
abstract final class DemoConfiguration {
  static core.ContestConfig of(DemoContestPlan plan) {
    final teams = plan.teamSize != null;
    return core.ContestConfig(
      core: {
        'teams_enabled': teams,
        'team_pilot_count': ?plan.teamSize,
        'team_protection': teams,
        'roles_enabled': plan.helpers > 0,
        'draw_mode': core.DrawMode.standardManOnMan.json,
        'lane_mode': core.LaneMode.none.json,
        'group_score_mode': core.GroupScoreMode.normalized.json,
        'rounding_mode': core.RoundingMode.round.json,
        'decimal_places': 1,
        'drop_after_rounds': <int>[],
        'tiebreaker_enabled': false,
        'classes_enabled': plan.classes,
        'models_enabled': false,
        'participant_numbers_enabled': plan.classes || teams,
        'review_requests_enabled': true,
        'public_update_mode': core.PublicUpdateMode.roundCompletion.json,
      },
      discipline: _disciplineDefaults(plan.disciplineProfileId),
    );
  }

  static Map<String, Object?> _disciplineDefaults(core.Id profileId) {
    final profile = core.SystemDisciplineProfiles.all.firstWhere(
      (p) => p.profile.id == profileId,
    );
    return {
      for (final field in profile.configFields)
        if (field.fieldType != core.ConfigFieldType.landing &&
            field.defaultValue != null)
          field.fieldKey: field.defaultValue,
    };
  }
}
