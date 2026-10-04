// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discipline_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisciplineRule _$DisciplineRuleFromJson(Map<String, dynamic> json) =>
    DisciplineRule(
      id: const IdConverter().fromJson(json['id'] as String),
      disciplineProfileId: const IdConverter().fromJson(
        json['discipline_profile_id'] as String,
      ),
      ruleKey: json['rule_key'] as String,
      ruleType: $enumDecode(_$RuleTypeEnumMap, json['rule_type']),
      condition: json['condition'] as String?,
      effect: json['effect'] as String?,
      appliesTo: (json['applies_to'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      dependsOn:
          (json['depends_on'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      displayName: json['display_name'] as String?,
      description: json['description'] as String?,
      autoScoreZero: json['auto_score_zero'] as bool? ?? true,
      affectsOtherFields:
          (json['affects_other_fields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      createdAt: const UtcTimestampConverter().fromJson(
        json['created_at'] as String,
      ),
    );

Map<String, dynamic> _$DisciplineRuleToJson(DisciplineRule instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'discipline_profile_id': const IdConverter().toJson(
        instance.disciplineProfileId,
      ),
      'rule_key': instance.ruleKey,
      'rule_type': _$RuleTypeEnumMap[instance.ruleType]!,
      'condition': instance.condition,
      'effect': instance.effect,
      'applies_to': instance.appliesTo,
      'depends_on': instance.dependsOn,
      'display_name': instance.displayName,
      'description': instance.description,
      'auto_score_zero': instance.autoScoreZero,
      'affects_other_fields': instance.affectsOtherFields,
      'display_order': instance.displayOrder,
      'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
    };

const _$RuleTypeEnumMap = {
  RuleType.calc: 'calc',
  RuleType.penalty: 'penalty',
  RuleType.zero: 'zero',
  RuleType.interaction: 'interaction',
  RuleType.other: 'other',
};
