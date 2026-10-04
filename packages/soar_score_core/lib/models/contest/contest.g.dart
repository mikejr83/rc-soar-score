// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Contest _$ContestFromJson(Map<String, dynamic> json) => Contest(
  id: const IdConverter().fromJson(json['id'] as String),
  name: json['name'] as String,
  startDateTime: const UtcTimestampConverter().fromJson(
    json['start_date_time'] as String,
  ),
  endDateTime: const UtcTimestampConverter().fromJson(
    json['end_date_time'] as String,
  ),
  timezone: json['timezone'] as String,
  host: json['host'] as String?,
  city: json['city'] as String?,
  state: json['state'] as String?,
  country: json['country'] as String?,
  ownerAccountId: _$JsonConverterFromJson<String, Id>(
    json['owner_account_id'],
    const IdConverter().fromJson,
  ),
  lifecycleState:
      $enumDecodeNullable(_$LifecycleStateEnumMap, json['lifecycle_state']) ??
      LifecycleState.created,
  scoringAccess:
      $enumDecodeNullable(_$ScoringAccessEnumMap, json['scoring_access']) ??
      ScoringAccess.closed,
  adminLock:
      $enumDecodeNullable(_$AdminLockEnumMap, json['admin_lock']) ??
      AdminLock.unlocked,
  resultsHiddenThroughRound: (json['results_hidden_through_round'] as num?)
      ?.toInt(),
  resultsHiddenAt: _$JsonConverterFromJson<String, DateTime>(
    json['results_hidden_at'],
    const UtcTimestampConverter().fromJson,
  ),
  localArchive: json['local_archive'] as bool? ?? false,
  createdAt: const UtcTimestampConverter().fromJson(
    json['created_at'] as String,
  ),
  updatedAt: const UtcTimestampConverter().fromJson(
    json['updated_at'] as String,
  ),
  revision: (json['revision'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ContestToJson(Contest instance) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'name': instance.name,
  'start_date_time': const UtcTimestampConverter().toJson(
    instance.startDateTime,
  ),
  'end_date_time': const UtcTimestampConverter().toJson(instance.endDateTime),
  'timezone': instance.timezone,
  'host': instance.host,
  'city': instance.city,
  'state': instance.state,
  'country': instance.country,
  'owner_account_id': _$JsonConverterToJson<String, Id>(
    instance.ownerAccountId,
    const IdConverter().toJson,
  ),
  'lifecycle_state': _$LifecycleStateEnumMap[instance.lifecycleState]!,
  'scoring_access': _$ScoringAccessEnumMap[instance.scoringAccess]!,
  'admin_lock': _$AdminLockEnumMap[instance.adminLock]!,
  'results_hidden_through_round': instance.resultsHiddenThroughRound,
  'results_hidden_at': _$JsonConverterToJson<String, DateTime>(
    instance.resultsHiddenAt,
    const UtcTimestampConverter().toJson,
  ),
  'local_archive': instance.localArchive,
  'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
  'updated_at': const UtcTimestampConverter().toJson(instance.updatedAt),
  'revision': instance.revision,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

const _$LifecycleStateEnumMap = {
  LifecycleState.created: 'Created',
  LifecycleState.configuring: 'Configuring',
  LifecycleState.ready: 'Ready',
  LifecycleState.running: 'Running',
  LifecycleState.completed: 'Completed',
};

const _$ScoringAccessEnumMap = {
  ScoringAccess.closed: 'Closed',
  ScoringAccess.open: 'Open',
};

const _$AdminLockEnumMap = {
  AdminLock.unlocked: 'Unlocked',
  AdminLock.locked: 'Locked',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
