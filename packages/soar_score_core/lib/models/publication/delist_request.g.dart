// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delist_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DelistRequest _$DelistRequestFromJson(Map<String, dynamic> json) =>
    DelistRequest(
      id: const IdConverter().fromJson(json['id'] as String),
      publicationId: const IdConverter().fromJson(
        json['publication_id'] as String,
      ),
      requestedBy: const IdConverter().fromJson(json['requested_by'] as String),
      trigger: $enumDecode(_$DelistTriggerEnumMap, json['trigger']),
      reason: json['reason'] as String?,
      requestedAt: const UtcTimestampConverter().fromJson(
        json['requested_at'] as String,
      ),
      state:
          $enumDecodeNullable(_$DelistStateEnumMap, json['state']) ??
          DelistState.pending,
      decidedBy: _$JsonConverterFromJson<String, Id>(
        json['decided_by'],
        const IdConverter().fromJson,
      ),
      decidedAt: _$JsonConverterFromJson<String, DateTime>(
        json['decided_at'],
        const UtcTimestampConverter().fromJson,
      ),
      decisionNote: json['decision_note'] as String?,
    );

Map<String, dynamic> _$DelistRequestToJson(
  DelistRequest instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'publication_id': const IdConverter().toJson(instance.publicationId),
  'requested_by': const IdConverter().toJson(instance.requestedBy),
  'trigger': _$DelistTriggerEnumMap[instance.trigger]!,
  'reason': instance.reason,
  'requested_at': const UtcTimestampConverter().toJson(instance.requestedAt),
  'state': _$DelistStateEnumMap[instance.state]!,
  'decided_by': _$JsonConverterToJson<String, Id>(
    instance.decidedBy,
    const IdConverter().toJson,
  ),
  'decided_at': _$JsonConverterToJson<String, DateTime>(
    instance.decidedAt,
    const UtcTimestampConverter().toJson,
  ),
  'decision_note': instance.decisionNote,
};

const _$DelistTriggerEnumMap = {
  DelistTrigger.ownerRequest: 'owner_request',
  DelistTrigger.accountClosure: 'account_closure',
};

const _$DelistStateEnumMap = {
  DelistState.pending: 'pending',
  DelistState.approved: 'approved',
  DelistState.denied: 'denied',
  DelistState.withdrawn: 'withdrawn',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
