// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_model_link_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateModelLinkRequest _$UpdateModelLinkRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'UpdateModelLinkRequest',
  json,
  ($checkedConvert) {
    final val = UpdateModelLinkRequest(
      baseRevision: $checkedConvert('base_revision', (v) => (v as num).toInt()),
      modelName: $checkedConvert('model_name', (v) => v as String),
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
    'baseRevision': 'base_revision',
    'modelName': 'model_name',
    'modelId': 'model_id',
    'contestSpecificIdentifier': 'contest_specific_identifier',
  },
);

Map<String, dynamic> _$UpdateModelLinkRequestToJson(
  UpdateModelLinkRequest instance,
) => <String, dynamic>{
  'base_revision': instance.baseRevision,
  'model_name': instance.modelName,
  'manufacturer': instance.manufacturer,
  'model_id': instance.modelId,
  'contest_specific_identifier': instance.contestSpecificIdentifier,
};
