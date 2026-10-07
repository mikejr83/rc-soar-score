// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'late_add_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LateAddRequest _$LateAddRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LateAddRequest',
      json,
      ($checkedConvert) {
        final val = LateAddRequest(
          id: $checkedConvert(
            'id',
            (v) => const IdConverter().fromJson(v as String),
          ),
          contestParticipationId: $checkedConvert(
            'contest_participation_id',
            (v) => const IdConverter().fromJson(v as String),
          ),
          scheduledRoundId: $checkedConvert(
            'scheduled_round_id',
            (v) => const IdConverter().fromJson(v as String),
          ),
          creditedRoundId: $checkedConvert(
            'credited_round_id',
            (v) => _$JsonConverterFromJson<String, Id>(
              v,
              const IdConverter().fromJson,
            ),
          ),
          group: $checkedConvert('group', (v) => (v as num).toInt()),
          lane: $checkedConvert('lane', (v) => (v as num?)?.toInt()),
          reason: $checkedConvert('reason', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'contestParticipationId': 'contest_participation_id',
        'scheduledRoundId': 'scheduled_round_id',
        'creditedRoundId': 'credited_round_id',
      },
    );

Map<String, dynamic> _$LateAddRequestToJson(
  LateAddRequest instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'contest_participation_id': const IdConverter().toJson(
    instance.contestParticipationId,
  ),
  'scheduled_round_id': const IdConverter().toJson(instance.scheduledRoundId),
  'credited_round_id': _$JsonConverterToJson<String, Id>(
    instance.creditedRoundId,
    const IdConverter().toJson,
  ),
  'group': instance.group,
  'lane': instance.lane,
  'reason': instance.reason,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
