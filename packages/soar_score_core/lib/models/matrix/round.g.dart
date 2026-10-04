// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'round.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Round _$RoundFromJson(Map<String, dynamic> json) => Round(
  id: const IdConverter().fromJson(json['id'] as String),
  contestId: const IdConverter().fromJson(json['contest_id'] as String),
  matrixRevisionId: const IdConverter().fromJson(
    json['matrix_revision_id'] as String,
  ),
  ordinal: (json['ordinal'] as num).toInt(),
  groupCount: (json['group_count'] as num).toInt(),
  status:
      $enumDecodeNullable(_$RoundStatusEnumMap, json['status']) ??
      RoundStatus.open,
  supersededByRoundId: _$JsonConverterFromJson<String, Id>(
    json['superseded_by_round_id'],
    const IdConverter().fromJson,
  ),
  revision: (json['revision'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$RoundToJson(Round instance) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'contest_id': const IdConverter().toJson(instance.contestId),
  'matrix_revision_id': const IdConverter().toJson(instance.matrixRevisionId),
  'ordinal': instance.ordinal,
  'group_count': instance.groupCount,
  'status': _$RoundStatusEnumMap[instance.status]!,
  'superseded_by_round_id': _$JsonConverterToJson<String, Id>(
    instance.supersededByRoundId,
    const IdConverter().toJson,
  ),
  'revision': instance.revision,
};

const _$RoundStatusEnumMap = {
  RoundStatus.open: 'Open',
  RoundStatus.locked: 'Locked',
  RoundStatus.cancelled: 'Cancelled',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
