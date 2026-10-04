import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/rule_type.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'discipline_rule.g.dart';

/// A score, penalty, zero-score or field-interaction rule of a discipline.
///
/// System data. See `plan/data-model/entities/discipline_rule.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class DisciplineRule extends Equatable implements SyncScoped {
  DisciplineRule({
    required this.id,
    required this.disciplineProfileId,
    required String ruleKey,
    required this.ruleType,
    this.condition,
    this.effect,
    List<String>? appliesTo,
    List<String> dependsOn = const [],
    this.displayName,
    this.description,
    this.autoScoreZero = true,
    List<String> affectsOtherFields = const [],
    this.displayOrder = 0,
    required DateTime createdAt,
  }) : ruleKey = requireNotBlank(ruleKey, 'ruleKey'),
       appliesTo = appliesTo == null ? null : List.unmodifiable(appliesTo),
       dependsOn = List.unmodifiable(dependsOn),
       affectsOtherFields = List.unmodifiable(affectsOtherFields),
       createdAt = createdAt.toUtc() {
    if (ruleType == RuleType.zero &&
        (displayName == null || displayName!.trim().isEmpty)) {
      throw ArgumentError('a zero rule needs a display_name');
    }
    if (dependsOn.contains(this.ruleKey)) {
      throw ArgumentError('a rule cannot depend on itself');
    }
  }

  factory DisciplineRule.fromJson(Map<String, Object?> json) =>
      _$DisciplineRuleFromJson(json);

  final Id id;
  final Id disciplineProfileId;

  /// Unique within the profile.
  final String ruleKey;

  final RuleType ruleType;

  /// The condition expression, for example `motor_restart == true`.
  final String? condition;

  /// The outcome when the condition is met, for example `score = 0`.
  final String? effect;

  /// Field or formula keys the rule interacts with.
  final List<String>? appliesTo;

  /// Rule keys that must be evaluated first.
  final List<String> dependsOn;

  /// Screen label; required for a zero rule.
  final String? displayName;

  final String? description;

  /// Whether selecting this zero reason scores the flight as 0.
  final bool autoScoreZero;

  /// Field keys that become disabled or zeroed when this is selected.
  final List<String> affectsOtherFields;

  final int displayOrder;
  final DateTime createdAt;

  @override
  SyncScope get syncScope => SyncScope.system;

  Map<String, Object?> toJson() => _$DisciplineRuleToJson(this);

  @override
  List<Object?> get props => [
    id,
    disciplineProfileId,
    ruleKey,
    ruleType,
    condition,
    effect,
    appliesTo,
    dependsOn,
    displayName,
    description,
    autoScoreZero,
    affectsOtherFields,
    displayOrder,
    createdAt,
  ];
}
