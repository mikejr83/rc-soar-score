// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_catalog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModelCatalog _$ModelCatalogFromJson(Map<String, dynamic> json) => ModelCatalog(
  id: const IdConverter().fromJson(json['id'] as String),
  ownerAccountId: const IdConverter().fromJson(
    json['owner_account_id'] as String,
  ),
  participantProfileId: const IdConverter().fromJson(
    json['participant_profile_id'] as String,
  ),
  name: json['name'] as String,
  manufacturer: json['manufacturer'] as String?,
  modelId: json['model_id'] as String?,
  revision: (json['revision'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ModelCatalogToJson(ModelCatalog instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'owner_account_id': const IdConverter().toJson(instance.ownerAccountId),
      'participant_profile_id': const IdConverter().toJson(
        instance.participantProfileId,
      ),
      'name': instance.name,
      'manufacturer': instance.manufacturer,
      'model_id': instance.modelId,
      'revision': instance.revision,
    };
