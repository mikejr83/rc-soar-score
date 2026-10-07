// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'move_assignment_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MoveAssignmentRequest _$MoveAssignmentRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'MoveAssignmentRequest',
  json,
  ($checkedConvert) {
    final val = MoveAssignmentRequest(
      id: $checkedConvert(
        'id',
        (v) => const IdConverter().fromJson(v as String),
      ),
      scheduledRoundId: $checkedConvert(
        'scheduled_round_id',
        (v) => _$JsonConverterFromJson<String, Id>(
          v,
          const IdConverter().fromJson,
        ),
      ),
      group: $checkedConvert('group', (v) => (v as num).toInt()),
      lane: $checkedConvert('lane', (v) => (v as num?)?.toInt()),
      reason: $checkedConvert('reason', (v) => v as String),
      overrideLocks: $checkedConvert(
        'override_locks',
        (v) => v as bool? ?? false,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'scheduledRoundId': 'scheduled_round_id',
    'overrideLocks': 'override_locks',
  },
);

Map<String, dynamic> _$MoveAssignmentRequestToJson(
  MoveAssignmentRequest instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'scheduled_round_id': _$JsonConverterToJson<String, Id>(
    instance.scheduledRoundId,
    const IdConverter().toJson,
  ),
  'group': instance.group,
  'lane': instance.lane,
  'reason': instance.reason,
  'override_locks': instance.overrideLocks,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
