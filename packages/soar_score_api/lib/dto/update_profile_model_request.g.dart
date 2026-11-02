// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_profile_model_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateProfileModelRequest _$UpdateProfileModelRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UpdateProfileModelRequest', json, ($checkedConvert) {
  final val = UpdateProfileModelRequest(
    baseRevision: $checkedConvert('base_revision', (v) => (v as num).toInt()),
    name: $checkedConvert('name', (v) => v as String),
    manufacturer: $checkedConvert('manufacturer', (v) => v as String?),
    modelId: $checkedConvert('model_id', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'baseRevision': 'base_revision', 'modelId': 'model_id'});

Map<String, dynamic> _$UpdateProfileModelRequestToJson(
  UpdateProfileModelRequest instance,
) => <String, dynamic>{
  'base_revision': instance.baseRevision,
  'name': instance.name,
  'manufacturer': instance.manufacturer,
  'model_id': instance.modelId,
};
