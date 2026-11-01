// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_model_link_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddModelLinkRequest _$AddModelLinkRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AddModelLinkRequest',
      json,
      ($checkedConvert) {
        final val = AddModelLinkRequest(
          id: $checkedConvert(
            'id',
            (v) => const IdConverter().fromJson(v as String),
          ),
          modelCatalogId: $checkedConvert(
            'model_catalog_id',
            (v) => _$JsonConverterFromJson<String, Id>(
              v,
              const IdConverter().fromJson,
            ),
          ),
          modelName: $checkedConvert('model_name', (v) => v as String?),
          manufacturer: $checkedConvert('manufacturer', (v) => v as String?),
          modelId: $checkedConvert('model_id', (v) => v as String?),
          contestSpecificIdentifier: $checkedConvert(
            'contest_specific_identifier',
            (v) => v as String?,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'modelCatalogId': 'model_catalog_id',
        'modelName': 'model_name',
        'modelId': 'model_id',
        'contestSpecificIdentifier': 'contest_specific_identifier',
      },
    );

Map<String, dynamic> _$AddModelLinkRequestToJson(
  AddModelLinkRequest instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'model_catalog_id': _$JsonConverterToJson<String, Id>(
    instance.modelCatalogId,
    const IdConverter().toJson,
  ),
  'model_name': instance.modelName,
  'manufacturer': instance.manufacturer,
  'model_id': instance.modelId,
  'contest_specific_identifier': instance.contestSpecificIdentifier,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
