import 'package:soar_score_core/soar_score_core.dart';

/// A small profile used to test the framework.
class FakeProfile extends ScoringProfile {
  FakeProfile({this.version = 1, this.type = DisciplineType.f5j});

  final int version;
  final DisciplineType type;

  @override
  DisciplineType get discipline => type;

  @override
  int get rulesVersion => version;

  @override
  Map<String, Object?> get defaultOptions => {'group_score_mode': 'Normalized'};

  @override
  final fields = [
    ScoringFieldDefinition(
      id: 'time',
      label: 'Time',
      type: ScoreFieldType.time,
      unit: 's',
      precision: 1,
      min: 0,
      max: 600,
      required: true,
    ),
    ScoringFieldDefinition(
      id: 'altitude',
      label: 'Altitude',
      type: ScoreFieldType.int,
      unit: 'm',
      min: 1,
    ),
    ScoringFieldDefinition(
      id: 'late',
      label: 'Late landing',
      type: ScoreFieldType.bool,
      kind: ScoreFieldKind.statusFlag,
    ),
    ScoringFieldDefinition(
      id: 'mode',
      label: 'Mode',
      type: ScoreFieldType.enumeration,
      allowedValues: ['a', 'b'],
    ),
    ScoringFieldDefinition(
      id: 'raw_score',
      label: 'Raw score',
      type: ScoreFieldType.float,
      kind: ScoreFieldKind.derived,
    ),
  ];

  @override
  List<ScoringIssue> validateCombination(Map<String, Object?> components) => [
    if (components['late'] == true && components['altitude'] == null)
      const ScoringIssue(code: 'combination', message: 'late needs altitude'),
  ];
}
