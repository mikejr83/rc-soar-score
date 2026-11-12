// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installation_activation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstallationActivation _$InstallationActivationFromJson(
  Map<String, dynamic> json,
) => InstallationActivation(
  id: const IdConverter().fromJson(json['id'] as String),
  contestId: const IdConverter().fromJson(json['contest_id'] as String),
  installationId: const IdConverter().fromJson(
    json['installation_id'] as String,
  ),
  activatedBy: const IdConverter().fromJson(json['activated_by'] as String),
  kind: $enumDecode(_$ActivationKindEnumMap, json['kind']),
  activatedAt: const UtcTimestampConverter().fromJson(
    json['activated_at'] as String,
  ),
  endedAt: _$JsonConverterFromJson<String, DateTime>(
    json['ended_at'],
    const UtcTimestampConverter().fromJson,
  ),
  uploadOpen: json['upload_open'] as bool? ?? false,
);

Map<String, dynamic> _$InstallationActivationToJson(
  InstallationActivation instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'contest_id': const IdConverter().toJson(instance.contestId),
  'installation_id': const IdConverter().toJson(instance.installationId),
  'activated_by': const IdConverter().toJson(instance.activatedBy),
  'kind': _$ActivationKindEnumMap[instance.kind]!,
  'activated_at': const UtcTimestampConverter().toJson(instance.activatedAt),
  'ended_at': _$JsonConverterToJson<String, DateTime>(
    instance.endedAt,
    const UtcTimestampConverter().toJson,
  ),
  'upload_open': instance.uploadOpen,
};

const _$ActivationKindEnumMap = {
  ActivationKind.initial: 'Initial',
  ActivationKind.replacement: 'Replacement',
  ActivationKind.reclaim: 'Reclaim',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
