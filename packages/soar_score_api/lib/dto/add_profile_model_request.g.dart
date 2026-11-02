// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_profile_model_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddProfileModelRequest _$AddProfileModelRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AddProfileModelRequest', json, ($checkedConvert) {
  final val = AddProfileModelRequest(
    id: $checkedConvert('id', (v) => const IdConverter().fromJson(v as String)),
    name: $checkedConvert('name', (v) => v as String),
    manufacturer: $checkedConvert('manufacturer', (v) => v as String?),
    modelId: $checkedConvert('model_id', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'modelId': 'model_id'});

Map<String, dynamic> _$AddProfileModelRequestToJson(
  AddProfileModelRequest instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'name': instance.name,
  'manufacturer': instance.manufacturer,
  'model_id': instance.modelId,
};
