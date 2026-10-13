// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activate_installation_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivateInstallationRequest _$ActivateInstallationRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ActivateInstallationRequest', json, ($checkedConvert) {
  final val = ActivateInstallationRequest(
    installationId: $checkedConvert(
      'installation_id',
      (v) => const IdConverter().fromJson(v as String),
    ),
    kind: $checkedConvert(
      'kind',
      (v) => $enumDecode(_$ActivationKindEnumMap, v),
    ),
  );
  return val;
}, fieldKeyMap: const {'installationId': 'installation_id'});

Map<String, dynamic> _$ActivateInstallationRequestToJson(
  ActivateInstallationRequest instance,
) => <String, dynamic>{
  'installation_id': const IdConverter().toJson(instance.installationId),
  'kind': _$ActivationKindEnumMap[instance.kind]!,
};

const _$ActivationKindEnumMap = {
  ActivationKind.initial: 'Initial',
  ActivationKind.replacement: 'Replacement',
  ActivationKind.reclaim: 'Reclaim',
};
