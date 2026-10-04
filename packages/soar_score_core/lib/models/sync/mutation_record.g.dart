// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mutation_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MutationRecord _$MutationRecordFromJson(Map<String, dynamic> json) =>
    MutationRecord(
      id: const IdConverter().fromJson(json['id'] as String),
      contestId: _$JsonConverterFromJson<String, Id>(
        json['contest_id'],
        const IdConverter().fromJson,
      ),
      ownerAccountId: _$JsonConverterFromJson<String, Id>(
        json['owner_account_id'],
        const IdConverter().fromJson,
      ),
      sequence: (json['sequence'] as num?)?.toInt(),
      entityType: json['entity_type'] as String,
      entityId: const IdConverter().fromJson(json['entity_id'] as String),
      baseRevision: (json['base_revision'] as num?)?.toInt(),
      clientMutationId: json['client_mutation_id'] as String,
      actorId: _$JsonConverterFromJson<String, Id>(
        json['actor_id'],
        const IdConverter().fromJson,
      ),
      authority: $enumDecode(_$AuthorityEnumMap, json['authority']),
      sourceInstallationId: _$JsonConverterFromJson<String, Id>(
        json['source_installation_id'],
        const IdConverter().fromJson,
      ),
      sourceDevice: json['source_device'] as String?,
      clientTime: const UtcTimestampConverter().fromJson(
        json['client_time'] as String,
      ),
      serverAcceptanceTime: _$JsonConverterFromJson<String, DateTime>(
        json['server_acceptance_time'],
        const UtcTimestampConverter().fromJson,
      ),
      serverRejectionTime: _$JsonConverterFromJson<String, DateTime>(
        json['server_rejection_time'],
        const UtcTimestampConverter().fromJson,
      ),
      payload: json['payload'] as Map<String, dynamic>,
      outcome:
          $enumDecodeNullable(_$MutationOutcomeEnumMap, json['outcome']) ??
          MutationOutcome.pending,
      reasonCode: json['reason_code'] as String?,
      errorMessage: json['error_message'] as String?,
      dependsOnMutationId: _$JsonConverterFromJson<String, Id>(
        json['depends_on_mutation_id'],
        const IdConverter().fromJson,
      ),
    );

Map<String, dynamic> _$MutationRecordToJson(MutationRecord instance) =>
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
      'sequence': instance.sequence,
      'entity_type': instance.entityType,
      'entity_id': const IdConverter().toJson(instance.entityId),
      'base_revision': instance.baseRevision,
      'client_mutation_id': instance.clientMutationId,
      'actor_id': _$JsonConverterToJson<String, Id>(
        instance.actorId,
        const IdConverter().toJson,
      ),
      'authority': _$AuthorityEnumMap[instance.authority]!,
      'source_installation_id': _$JsonConverterToJson<String, Id>(
        instance.sourceInstallationId,
        const IdConverter().toJson,
      ),
      'source_device': instance.sourceDevice,
      'client_time': const UtcTimestampConverter().toJson(instance.clientTime),
      'server_acceptance_time': _$JsonConverterToJson<String, DateTime>(
        instance.serverAcceptanceTime,
        const UtcTimestampConverter().toJson,
      ),
      'server_rejection_time': _$JsonConverterToJson<String, DateTime>(
        instance.serverRejectionTime,
        const UtcTimestampConverter().toJson,
      ),
      'payload': instance.payload,
      'outcome': _$MutationOutcomeEnumMap[instance.outcome]!,
      'reason_code': instance.reasonCode,
      'error_message': instance.errorMessage,
      'depends_on_mutation_id': _$JsonConverterToJson<String, Id>(
        instance.dependsOnMutationId,
        const IdConverter().toJson,
      ),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

const _$AuthorityEnumMap = {
  Authority.director: 'Director',
  Authority.participant: 'Participant',
  Authority.helper: 'Helper',
  Authority.system: 'System',
  Authority.administrator: 'Administrator',
};

const _$MutationOutcomeEnumMap = {
  MutationOutcome.pending: 'Pending',
  MutationOutcome.accepted: 'Accepted',
  MutationOutcome.rejected: 'Rejected',
  MutationOutcome.conflict: 'Conflict',
  MutationOutcome.skipped: 'Skipped',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
