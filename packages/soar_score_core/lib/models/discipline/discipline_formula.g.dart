// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discipline_formula.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisciplineFormula _$DisciplineFormulaFromJson(Map<String, dynamic> json) =>
    DisciplineFormula(
      id: const IdConverter().fromJson(json['id'] as String),
      disciplineProfileId: const IdConverter().fromJson(
        json['discipline_profile_id'] as String,
      ),
      formulaKey: json['formula_key'] as String,
      description: json['description'] as String?,
      formulaText: json['formula_text'] as String,
      formulaType: $enumDecode(_$FormulaTypeEnumMap, json['formula_type']),
      inputs: json['inputs'] as Map<String, dynamic>,
      outputs: json['outputs'] as Map<String, dynamic>?,
      dependsOn:
          (json['depends_on'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isPrimary: json['is_primary'] as bool? ?? false,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      createdAt: const UtcTimestampConverter().fromJson(
        json['created_at'] as String,
      ),
    );

Map<String, dynamic> _$DisciplineFormulaToJson(DisciplineFormula instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'discipline_profile_id': const IdConverter().toJson(
        instance.disciplineProfileId,
      ),
      'formula_key': instance.formulaKey,
      'description': instance.description,
      'formula_text': instance.formulaText,
      'formula_type': _$FormulaTypeEnumMap[instance.formulaType]!,
      'inputs': instance.inputs,
      'outputs': instance.outputs,
      'depends_on': instance.dependsOn,
      'is_primary': instance.isPrimary,
      'display_order': instance.displayOrder,
      'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
    };

const _$FormulaTypeEnumMap = {
  FormulaType.raw: 'raw',
  FormulaType.intermediate: 'intermediate',
  FormulaType.penalty: 'penalty',
  FormulaType.finalFormula: 'final',
  FormulaType.normalized: 'normalized',
};
