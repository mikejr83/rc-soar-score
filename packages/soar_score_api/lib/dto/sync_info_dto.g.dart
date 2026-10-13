// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_info_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncInfoDto _$SyncInfoDtoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'SyncInfoDto',
  json,
  ($checkedConvert) {
    final val = SyncInfoDto(
      protocolVersion: $checkedConvert(
        'protocol_version',
        (v) => (v as num).toInt(),
      ),
      minProtocolVersion: $checkedConvert(
        'min_protocol_version',
        (v) => (v as num).toInt(),
      ),
      minSchemaVersion: $checkedConvert(
        'min_schema_version',
        (v) => (v as num).toInt(),
      ),
      maxSchemaVersion: $checkedConvert(
        'max_schema_version',
        (v) => (v as num).toInt(),
      ),
      serverTime: $checkedConvert(
        'server_time',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'protocolVersion': 'protocol_version',
    'minProtocolVersion': 'min_protocol_version',
    'minSchemaVersion': 'min_schema_version',
    'maxSchemaVersion': 'max_schema_version',
    'serverTime': 'server_time',
  },
);

Map<String, dynamic> _$SyncInfoDtoToJson(SyncInfoDto instance) =>
    <String, dynamic>{
      'protocol_version': instance.protocolVersion,
      'min_protocol_version': instance.minProtocolVersion,
      'min_schema_version': instance.minSchemaVersion,
      'max_schema_version': instance.maxSchemaVersion,
      'server_time': instance.serverTime.toIso8601String(),
    };
