import '../../enums/discipline_type.dart';
import '../../enums/score_field_kind.dart';
import '../../enums/score_field_type.dart';
import '../profile/scoring_field_definition.dart';
import '../profile/scoring_issue.dart';
import '../profile/scoring_profile.dart';
import 'ales_options.dart';

/// The official ALES scoring profile, rules version 1.
///
/// Field keys and option keys follow
/// `plan/data-model/examples/disciplines/ales.md`.
class AlesProfile extends ScoringProfile {
  AlesProfile();

  @override
  DisciplineType get discipline => DisciplineType.ales;

  @override
  int get rulesVersion => 1;

  /// The platform rounding default (1 decimal) applies: the ALES rules do not
  /// give one.
  @override
  Map<String, Object?> get defaultOptions => const {
    'target_time': 600,
    'points_per_second': 1.0,
    'fractional_seconds': 0,
    'group_score_mode': 'Time',
    'rounding_mode': 'Round',
    'decimal_places': 1,
  };

  @override
  final List<ScoringFieldDefinition> fields = List.unmodifiable([
    ScoringFieldDefinition(
      id: 'time_flown',
      label: 'Time Flown',
      type: ScoreFieldType.time,
      unit: 's',
      precision: 3,
      min: 0,
    ),
    ScoringFieldDefinition(
      id: 'landing',
      label: 'Landing',
      type: ScoreFieldType.landing,
    ),
    ScoringFieldDefinition(
      id: 'motor_restart',
      label: 'Motor Restart',
      type: ScoreFieldType.bool,
      kind: ScoreFieldKind.statusFlag,
    ),
    ScoringFieldDefinition(
      id: 'out_of_bounds',
      label: 'Out of Bounds',
      type: ScoreFieldType.bool,
      kind: ScoreFieldKind.statusFlag,
    ),
    ScoringFieldDefinition(
      id: 'overflight_gt_one_min',
      label: 'Over-Flight of Greater Than One Minute',
      type: ScoreFieldType.bool,
      kind: ScoreFieldKind.statusFlag,
    ),
    ScoringFieldDefinition(
      id: 'raw_score',
      label: 'Raw Score',
      type: ScoreFieldType.float,
      kind: ScoreFieldKind.derived,
    ),
  ]);

  static const _zeroStatusIds = [
    'motor_restart',
    'out_of_bounds',
    'overflight_gt_one_min',
  ];

  /// Motor restart, out of bounds and over-flight are mutually exclusive;
  /// each one alone forces a zero.
  @override
  List<ScoringIssue> validateCombination(Map<String, Object?> components) {
    final selected = _zeroStatusIds.where((id) => components[id] == true);
    if (selected.length <= 1) return const [];
    return const [
      ScoringIssue(
        code: 'exclusive_status',
        message:
            'Select only one of motor restart, out of bounds, or over-flight '
            'of more than one minute.',
      ),
    ];
  }

  /// The parsed options of a contest's [overrides] over the defaults.
  AlesOptions options([Map<String, Object?>? overrides]) =>
      AlesOptions.fromMap(resolveOptions(overrides));
}
