// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_installation_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterInstallationRequest _$RegisterInstallationRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RegisterInstallationRequest', json, ($checkedConvert) {
  final val = RegisterInstallationRequest(
    id: $checkedConvert('id', (v) => const IdConverter().fromJson(v as String)),
    label: $checkedConvert('label', (v) => v as String),
    platform: $checkedConvert(
      'platform',
      (v) => $enumDecode(_$PlatformEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$RegisterInstallationRequestToJson(
  RegisterInstallationRequest instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'label': instance.label,
  'platform': _$PlatformEnumMap[instance.platform]!,
};

const _$PlatformEnumMap = {
  Platform.web: 'Web',
  Platform.windows: 'Windows',
  Platform.other: 'Other',
};
