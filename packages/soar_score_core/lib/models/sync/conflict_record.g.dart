// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conflict_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConflictRecord _$ConflictRecordFromJson(Map<String, dynamic> json) =>
    ConflictRecord(
      id: const IdConverter().fromJson(json['id'] as String),
      contestId: _$JsonConverterFromJson<String, Id>(
        json['contest_id'],
        const IdConverter().fromJson,
      ),
      ownerAccountId: _$JsonConverterFromJson<String, Id>(
        json['owner_account_id'],
        const IdConverter().fromJson,
      ),
      entityType: json['entity_type'] as String,
      entityId: const IdConverter().fromJson(json['entity_id'] as String),
      acceptedMutationId: _$JsonConverterFromJson<String, Id>(
        json['accepted_mutation_id'],
        const IdConverter().fromJson,
      ),
      competingMutationId: const IdConverter().fromJson(
        json['competing_mutation_id'] as String,
      ),
      reasonCode: json['reason_code'] as String,
      reason: json['reason'] as String?,
      requiresAction: json['requires_action'] as bool? ?? true,
      resolution:
          $enumDecodeNullable(
            _$ConflictResolutionEnumMap,
            json['resolution'],
          ) ??
          ConflictResolution.pending,
      resolutionChoice: $enumDecodeNullable(
        _$ConflictResolutionChoiceEnumMap,
        json['resolution_choice'],
      ),
      createdAt: const UtcTimestampConverter().fromJson(
        json['created_at'] as String,
      ),
      resolvedAt: _$JsonConverterFromJson<String, DateTime>(
        json['resolved_at'],
        const UtcTimestampConverter().fromJson,
      ),
      resolvedBy: _$JsonConverterFromJson<String, Id>(
        json['resolved_by'],
        const IdConverter().fromJson,
      ),
      acceptedPayload: json['accepted_payload'] as Map<String, dynamic>?,
      competingPayload: json['competing_payload'] as Map<String, dynamic>?,
      entityRevision: (json['entity_revision'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ConflictRecordToJson(ConflictRecord instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'contest_id': _$JsonConverterToJson<String, Id>(
        instance.contestId,
        const IdConverter().toJson,
      ),
      'owner_account_id': _$JsonConverterToJson<String, Id>(
        instance.ownerAccountId,
        const IdConverter().toJson,
      ),
      'entity_type': instance.entityType,
      'entity_id': const IdConverter().toJson(instance.entityId),
      'accepted_mutation_id': _$JsonConverterToJson<String, Id>(
        instance.acceptedMutationId,
        const IdConverter().toJson,
      ),
      'competing_mutation_id': const IdConverter().toJson(
        instance.competingMutationId,
      ),
      'reason_code': instance.reasonCode,
      'reason': instance.reason,
      'requires_action': instance.requiresAction,
      'resolution': _$ConflictResolutionEnumMap[instance.resolution]!,
      'resolution_choice':
          _$ConflictResolutionChoiceEnumMap[instance.resolutionChoice],
      'created_at': const UtcTimestampConverter().toJson(instance.createdAt),
      'resolved_at': _$JsonConverterToJson<String, DateTime>(
        instance.resolvedAt,
        const UtcTimestampConverter().toJson,
      ),
      'resolved_by': _$JsonConverterToJson<String, Id>(
        instance.resolvedBy,
        const IdConverter().toJson,
      ),
      'accepted_payload': instance.acceptedPayload,
      'competing_payload': instance.competingPayload,
      'entity_revision': instance.entityRevision,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

const _$ConflictResolutionEnumMap = {
  ConflictResolution.pending: 'Pending',
  ConflictResolution.automatic: 'Automatic',
  ConflictResolution.manual: 'Manual',
};

const _$ConflictResolutionChoiceEnumMap = {
  ConflictResolutionChoice.keptAccepted: 'KeptAccepted',
  ConflictResolutionChoice.tookCompeting: 'TookCompeting',
  ConflictResolutionChoice.merged: 'Merged',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
