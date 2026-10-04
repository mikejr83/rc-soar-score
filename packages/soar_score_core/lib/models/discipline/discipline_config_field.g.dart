// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discipline_config_field.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisciplineConfigField _$DisciplineConfigFieldFromJson(
  Map<String, dynamic> json,
) => DisciplineConfigField(
  id: const IdConverter().fromJson(json['id'] as String),
  disciplineProfileId: const IdConverter().fromJson(
    json['discipline_profile_id'] as String,
  ),
  fieldKey: json['field_key'] as String,
  fieldType: $enumDecode(_$ConfigFieldTypeEnumMap, json['field_type']),
  name: json['name'] as String,
  description: json['description'] as String?,
  unit: json['unit'] as String?,
  required: json['required'] as bool? ?? false,
  defaultValue: json['default_value'],
  options: json['options'] as List<dynamic>?,
  validation: json['validation'] as Map<String, dynamic>?,
  displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
  createdAt: const UtcTimestampConverter().fromJson(
    json['created_at'] as String,
  ),
);

Map<String, dynamic> _$DisciplineConfigFieldToJson(
  DisciplineConfigField instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'discipline_profile_id': const IdConverter().toJson(
    instance.disciplineProfileId,
  ),
  'field_key': instance.fieldKey,
  'field_type': _$ConfigFieldTypeEnumMap[instance.fieldType]!,
  'name': instance.name,
  'description': instance.description,
  'unit': instance.unit,
  'required': instance.required,
  'default_value': instance.defaultValue,
  'options': instance.options,
  'validation': instance.validation,
  'display_order': instance.displayOrder,
  'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
};

const _$ConfigFieldTypeEnumMap = {
  ConfigFieldType.string: 'string',
  ConfigFieldType.int: 'int',
  ConfigFieldType.float: 'float',
  ConfigFieldType.bool: 'bool',
  ConfigFieldType.enumeration: 'enum',
  ConfigFieldType.landing: 'landing',
};
