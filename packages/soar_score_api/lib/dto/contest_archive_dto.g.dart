// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contest_archive_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContestArchiveDto _$ContestArchiveDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ContestArchiveDto',
      json,
      ($checkedConvert) {
        final val = ContestArchiveDto(
          protocolVersion: $checkedConvert(
            'protocol_version',
            (v) => (v as num).toInt(),
          ),
          schemaVersion: $checkedConvert(
            'schema_version',
            (v) => (v as num).toInt(),
          ),
          contestId: $checkedConvert(
            'contest_id',
            (v) => const IdConverter().fromJson(v as String),
          ),
          serverSequence: $checkedConvert(
            'server_sequence',
            (v) => (v as num).toInt(),
          ),
          data: $checkedConvert('data', (v) => v as Map<String, dynamic>),
        );
        return val;
      },
      fieldKeyMap: const {
        'protocolVersion': 'protocol_version',
        'schemaVersion': 'schema_version',
        'contestId': 'contest_id',
        'serverSequence': 'server_sequence',
      },
    );

Map<String, dynamic> _$ContestArchiveDtoToJson(ContestArchiveDto instance) =>
    <String, dynamic>{
      'protocol_version': instance.protocolVersion,
      'schema_version': instance.schemaVersion,
      'contest_id': const IdConverter().toJson(instance.contestId),
      'server_sequence': instance.serverSequence,
      'data': instance.data,
    };
