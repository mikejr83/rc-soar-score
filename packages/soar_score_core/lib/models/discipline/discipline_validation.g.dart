// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discipline_validation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisciplineValidation _$DisciplineValidationFromJson(
  Map<String, dynamic> json,
) => DisciplineValidation(
  id: const IdConverter().fromJson(json['id'] as String),
  disciplineProfileId: const IdConverter().fromJson(
    json['discipline_profile_id'] as String,
  ),
  fieldKeys: (json['field_keys'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  constraintType: json['constraint_type'] as String,
  description: json['description'] as String?,
  appliesTo: json['applies_to'],
  message: json['message'] as String?,
  displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
  createdAt: const UtcTimestampConverter().fromJson(
    json['created_at'] as String,
  ),
);

Map<String, dynamic> _$DisciplineValidationToJson(
  DisciplineValidation instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'discipline_profile_id': const IdConverter().toJson(
    instance.disciplineProfileId,
  ),
  'field_keys': instance.fieldKeys,
  'constraint_type': instance.constraintType,
  'description': instance.description,
  'applies_to': instance.appliesTo,
  'message': instance.message,
  'display_order': instance.displayOrder,
  'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
};
