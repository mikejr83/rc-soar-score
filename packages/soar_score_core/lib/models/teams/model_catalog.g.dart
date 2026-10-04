// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_catalog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModelCatalog _$ModelCatalogFromJson(Map<String, dynamic> json) => ModelCatalog(
  id: const IdConverter().fromJson(json['id'] as String),
  name: json['name'] as String,
  manufacturer: json['manufacturer'] as String?,
  revision: (json['revision'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ModelCatalogToJson(ModelCatalog instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'name': instance.name,
      'manufacturer': instance.manufacturer,
      'revision': instance.revision,
    };
