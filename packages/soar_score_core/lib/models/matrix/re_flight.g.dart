// GENERATED CODE - DO NOT MODIFY BY HAND

part of 're_flight.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReFlight _$ReFlightFromJson(Map<String, dynamic> json) => ReFlight(
  id: const IdConverter().fromJson(json['id'] as String),
  contestId: const IdConverter().fromJson(json['contest_id'] as String),
  creditedRoundId: const IdConverter().fromJson(
    json['credited_round_id'] as String,
  ),
  sourceRoundId: const IdConverter().fromJson(
    json['source_round_id'] as String,
  ),
  sourceGroup: (json['source_group'] as num).toInt(),
  type: $enumDecode(_$ReFlightTypeEnumMap, json['type']),
  sequence: (json['sequence'] as num?)?.toInt() ?? 1,
  previousReflightId: _$JsonConverterFromJson<String, Id>(
    json['previous_reflight_id'],
    const IdConverter().fromJson,
  ),
  status:
      $enumDecodeNullable(_$ReFlightStatusEnumMap, json['status']) ??
      ReFlightStatus.proposed,
  reason: json['reason'] as String,
  scheduledRoundId: const IdConverter().fromJson(
    json['scheduled_round_id'] as String,
  ),
  flownGroup: (json['flown_group'] as num).toInt(),
  deviationAcknowledged: json['deviation_acknowledged'] as bool? ?? false,
  requestedGroupSize: (json['requested_group_size'] as num?)?.toInt(),
  achievableMaxSize: (json['achievable_max_size'] as num?)?.toInt(),
  sizeExceptionConfirmed: json['size_exception_confirmed'] as bool? ?? false,
  randomSeed: (json['random_seed'] as num?)?.toInt(),
  algorithmVersion: json['algorithm_version'] as String?,
  configRevisionId: const IdConverter().fromJson(
    json['config_revision_id'] as String,
  ),
  createdBy: const IdConverter().fromJson(json['created_by'] as String),
  createdAt: const UtcTimestampConverter().fromJson(
    json['created_at'] as String,
  ),
  groupFinalizedBy: _$JsonConverterFromJson<String, Id>(
    json['group_finalized_by'],
    const IdConverter().fromJson,
  ),
  groupFinalizedAt: _$JsonConverterFromJson<String, DateTime>(
    json['group_finalized_at'],
    const UtcTimestampConverter().fromJson,
  ),
  finalizedBy: _$JsonConverterFromJson<String, Id>(
    json['finalized_by'],
    const IdConverter().fromJson,
  ),
  finalizedAt: _$JsonConverterFromJson<String, DateTime>(
    json['finalized_at'],
    const UtcTimestampConverter().fromJson,
  ),
  cancelledBy: _$JsonConverterFromJson<String, Id>(
    json['cancelled_by'],
    const IdConverter().fromJson,
  ),
  cancelledAt: _$JsonConverterFromJson<String, DateTime>(
    json['cancelled_at'],
    const UtcTimestampConverter().fromJson,
  ),
  cancelReason: json['cancel_reason'] as String?,
  revision: (json['revision'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ReFlightToJson(ReFlight instance) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'contest_id': const IdConverter().toJson(instance.contestId),
  'credited_round_id': const IdConverter().toJson(instance.creditedRoundId),
  'source_round_id': const IdConverter().toJson(instance.sourceRoundId),
  'source_group': instance.sourceGroup,
  'type': _$ReFlightTypeEnumMap[instance.type]!,
  'sequence': instance.sequence,
  'previous_reflight_id': _$JsonConverterToJson<String, Id>(
    instance.previousReflightId,
    const IdConverter().toJson,
  ),
  'status': _$ReFlightStatusEnumMap[instance.status]!,
  'reason': instance.reason,
  'scheduled_round_id': const IdConverter().toJson(instance.scheduledRoundId),
  'flown_group': instance.flownGroup,
  'deviation_acknowledged': instance.deviationAcknowledged,
  'requested_group_size': instance.requestedGroupSize,
  'achievable_max_size': instance.achievableMaxSize,
  'size_exception_confirmed': instance.sizeExceptionConfirmed,
  'random_seed': instance.randomSeed,
  'algorithm_version': instance.algorithmVersion,
  'config_revision_id': const IdConverter().toJson(instance.configRevisionId),
  'created_by': const IdConverter().toJson(instance.createdBy),
  'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
  'group_finalized_by': _$JsonConverterToJson<String, Id>(
    instance.groupFinalizedBy,
    const IdConverter().toJson,
  ),
  'group_finalized_at': _$JsonConverterToJson<String, DateTime>(
    instance.groupFinalizedAt,
    const UtcTimestampConverter().toJson,
  ),
  'finalized_by': _$JsonConverterToJson<String, Id>(
    instance.finalizedBy,
    const IdConverter().toJson,
  ),
  'finalized_at': _$JsonConverterToJson<String, DateTime>(
    instance.finalizedAt,
    const UtcTimestampConverter().toJson,
  ),
  'cancelled_by': _$JsonConverterToJson<String, Id>(
    instance.cancelledBy,
    const IdConverter().toJson,
  ),
  'cancelled_at': _$JsonConverterToJson<String, DateTime>(
    instance.cancelledAt,
    const UtcTimestampConverter().toJson,
  ),
  'cancel_reason': instance.cancelReason,
  'revision': instance.revision,
};

const _$ReFlightTypeEnumMap = {
  ReFlightType.moveToGroup: 'MoveToGroup',
  ReFlightType.randomDraw: 'RandomDraw',
  ReFlightType.reflyEntireGroup: 'ReflyEntireGroup',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

const _$ReFlightStatusEnumMap = {
  ReFlightStatus.proposed: 'Proposed',
  ReFlightStatus.drawPending: 'DrawPending',
  ReFlightStatus.awaitingResponses: 'AwaitingResponses',
  ReFlightStatus.readyToFly: 'ReadyToFly',
  ReFlightStatus.finalized: 'Finalized',
  ReFlightStatus.cancelled: 'Cancelled',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
