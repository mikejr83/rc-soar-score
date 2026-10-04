// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contest_model_link.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContestModelLink _$ContestModelLinkFromJson(Map<String, dynamic> json) =>
    ContestModelLink(
      id: const IdConverter().fromJson(json['id'] as String),
      contestId: const IdConverter().fromJson(json['contest_id'] as String),
      contestParticipationId: const IdConverter().fromJson(
        json['contest_participation_id'] as String,
      ),
      modelCatalogId: _$JsonConverterFromJson<String, Id>(
        json['model_catalog_id'],
        const IdConverter().fromJson,
      ),
      modelName: json['model_name'] as String,
      manufacturer: json['manufacturer'] as String?,
      modelId: json['model_id'] as String,
      contestSpecificIdentifier: json['contest_specific_identifier'] as String?,
      revision: (json['revision'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ContestModelLinkToJson(ContestModelLink instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'contest_id': const IdConverter().toJson(instance.contestId),
      'contest_participation_id': const IdConverter().toJson(
        instance.contestParticipationId,
      ),
      'model_catalog_id': _$JsonConverterToJson<String, Id>(
        instance.modelCatalogId,
        const IdConverter().toJson,
      ),
      'model_name': instance.modelName,
      'manufacturer': instance.manufacturer,
      'model_id': instance.modelId,
      'contest_specific_identifier': instance.contestSpecificIdentifier,
      'revision': instance.revision,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
