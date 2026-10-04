// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discipline_score_field.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisciplineScoreField _$DisciplineScoreFieldFromJson(
  Map<String, dynamic> json,
) => DisciplineScoreField(
  id: const IdConverter().fromJson(json['id'] as String),
  disciplineProfileId: const IdConverter().fromJson(
    json['discipline_profile_id'] as String,
  ),
  fieldKey: json['field_key'] as String,
  fieldType: $enumDecode(_$ScoreFieldTypeEnumMap, json['field_type']),
  name: json['name'] as String,
  description: json['description'] as String?,
  fieldKind:
      $enumDecodeNullable(_$ScoreFieldKindEnumMap, json['field_kind']) ??
      ScoreFieldKind.input,
  unit: json['unit'] as String?,
  precision: (json['precision'] as num?)?.toInt(),
  required: json['required'] as bool? ?? false,
  defaultValue: json['default_value'],
  options: json['options'] as List<dynamic>?,
  validation: json['validation'] as Map<String, dynamic>?,
  displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
  isZeroReason: json['is_zero_reason'] as bool? ?? false,
  zeroReasonCode: json['zero_reason_code'] as String?,
  createdAt: const UtcTimestampConverter().fromJson(
    json['created_at'] as String,
  ),
);

Map<String, dynamic> _$DisciplineScoreFieldToJson(
  DisciplineScoreField instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'discipline_profile_id': const IdConverter().toJson(
    instance.disciplineProfileId,
  ),
  'field_key': instance.fieldKey,
  'field_type': _$ScoreFieldTypeEnumMap[instance.fieldType]!,
  'name': instance.name,
  'description': instance.description,
  'field_kind': _$ScoreFieldKindEnumMap[instance.fieldKind]!,
  'unit': instance.unit,
  'precision': instance.precision,
  'required': instance.required,
  'default_value': instance.defaultValue,
  'options': instance.options,
  'validation': instance.validation,
  'display_order': instance.displayOrder,
  'is_zero_reason': instance.isZeroReason,
  'zero_reason_code': instance.zeroReasonCode,
  'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
};

const _$ScoreFieldTypeEnumMap = {
  ScoreFieldType.string: 'string',
  ScoreFieldType.int: 'int',
  ScoreFieldType.float: 'float',
  ScoreFieldType.bool: 'bool',
  ScoreFieldType.enumeration: 'enum',
  ScoreFieldType.date: 'date',
  ScoreFieldType.time: 'time',
  ScoreFieldType.landing: 'landing',
};

const _$ScoreFieldKindEnumMap = {
  ScoreFieldKind.input: 'input',
  ScoreFieldKind.statusFlag: 'status_flag',
  ScoreFieldKind.derived: 'derived',
};
