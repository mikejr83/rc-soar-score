// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discipline_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DisciplineProfile _$DisciplineProfileFromJson(Map<String, dynamic> json) =>
    DisciplineProfile(
      id: const IdConverter().fromJson(json['id'] as String),
      type: $enumDecode(_$DisciplineTypeEnumMap, json['type']),
      version: (json['version'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      category: $enumDecode(_$DisciplineCategoryEnumMap, json['category']),
      defaultLandingTableId: _$JsonConverterFromJson<String, Id>(
        json['default_landing_table_id'],
        const IdConverter().fromJson,
      ),
      defaultOptions: json['default_options'] as Map<String, dynamic>?,
      status:
          $enumDecodeNullable(_$ProfileStatusEnumMap, json['status']) ??
          ProfileStatus.drafted,
      supersededBy: _$JsonConverterFromJson<String, Id>(
        json['superseded_by'],
        const IdConverter().fromJson,
      ),
      createdBy: const IdConverter().fromJson(json['created_by'] as String),
      createdAt: const UtcTimestampConverter().fromJson(
        json['created_at'] as String,
      ),
      updatedBy: _$JsonConverterFromJson<String, Id>(
        json['updated_by'],
        const IdConverter().fromJson,
      ),
      updatedAt: _$JsonConverterFromJson<String, DateTime>(
        json['updated_at'],
        const UtcTimestampConverter().fromJson,
      ),
    );

Map<String, dynamic> _$DisciplineProfileToJson(DisciplineProfile instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'type': _$DisciplineTypeEnumMap[instance.type]!,
      'version': instance.version,
      'name': instance.name,
      'description': instance.description,
      'category': _$DisciplineCategoryEnumMap[instance.category]!,
      'default_landing_table_id': _$JsonConverterToJson<String, Id>(
        instance.defaultLandingTableId,
        const IdConverter().toJson,
      ),
      'default_options': instance.defaultOptions,
      'status': _$ProfileStatusEnumMap[instance.status]!,
      'superseded_by': _$JsonConverterToJson<String, Id>(
        instance.supersededBy,
        const IdConverter().toJson,
      ),
      'created_by': const IdConverter().toJson(instance.createdBy),
      'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
      'updated_by': _$JsonConverterToJson<String, Id>(
        instance.updatedBy,
        const IdConverter().toJson,
      ),
      'updated_at': _$JsonConverterToJson<String, DateTime>(
        instance.updatedAt,
        const UtcTimestampConverter().toJson,
      ),
    };

const _$DisciplineTypeEnumMap = {
  DisciplineType.ales: 'ALES',
  DisciplineType.thermalDuration: 'ThermalDuration',
  DisciplineType.f3j: 'F3J',
  DisciplineType.f5j: 'F5J',
  DisciplineType.f3l: 'F3L',
  DisciplineType.f3k: 'F3K',
};

const _$DisciplineCategoryEnumMap = {
  DisciplineCategory.duration: 'duration',
  DisciplineCategory.multiple: 'multiple',
  DisciplineCategory.other: 'other',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

const _$ProfileStatusEnumMap = {
  ProfileStatus.drafted: 'drafted',
  ProfileStatus.published: 'published',
  ProfileStatus.superseded: 'superseded',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
