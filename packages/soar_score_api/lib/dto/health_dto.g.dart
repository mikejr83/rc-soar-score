// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthDto _$HealthDtoFromJson(Map<String, dynamic> json) => HealthDto(
  name: json['name'] as String,
  displayName: json['displayName'] as String,
  version: json['version'] as String,
  schemaRevision: (json['schemaRevision'] as num?)?.toInt(),
);

Map<String, dynamic> _$HealthDtoToJson(HealthDto instance) => <String, dynamic>{
  'name': instance.name,
  'displayName': instance.displayName,
  'version': instance.version,
  'schemaRevision': instance.schemaRevision,
};
