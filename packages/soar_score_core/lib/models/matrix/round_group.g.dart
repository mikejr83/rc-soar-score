// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'round_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoundGroup _$RoundGroupFromJson(Map<String, dynamic> json) => RoundGroup(
  id: const IdConverter().fromJson(json['id'] as String),
  contestId: const IdConverter().fromJson(json['contest_id'] as String),
  roundId: const IdConverter().fromJson(json['round_id'] as String),
  groupNumber: (json['group_number'] as num).toInt(),
  status:
      $enumDecodeNullable(_$GroupStatusEnumMap, json['status']) ??
      GroupStatus.open,
  lockedBy: _$JsonConverterFromJson<String, Id>(
    json['locked_by'],
    const IdConverter().fromJson,
  ),
  lockedAt: _$JsonConverterFromJson<String, DateTime>(
    json['locked_at'],
    const UtcTimestampConverter().fromJson,
  ),
  revision: (json['revision'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$RoundGroupToJson(RoundGroup instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'contest_id': const IdConverter().toJson(instance.contestId),
      'round_id': const IdConverter().toJson(instance.roundId),
      'group_number': instance.groupNumber,
      'status': _$GroupStatusEnumMap[instance.status]!,
      'locked_by': _$JsonConverterToJson<String, Id>(
        instance.lockedBy,
        const IdConverter().toJson,
      ),
      'locked_at': _$JsonConverterToJson<String, DateTime>(
        instance.lockedAt,
        const UtcTimestampConverter().toJson,
      ),
      'revision': instance.revision,
    };

const _$GroupStatusEnumMap = {
  GroupStatus.open: 'Open',
  GroupStatus.locked: 'Locked',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
