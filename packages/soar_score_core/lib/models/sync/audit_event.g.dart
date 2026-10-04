// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditEvent _$AuditEventFromJson(Map<String, dynamic> json) => AuditEvent(
  id: const IdConverter().fromJson(json['id'] as String),
  entityType: json['entity_type'] as String,
  entityId: const IdConverter().fromJson(json['entity_id'] as String),
  contestId: _$JsonConverterFromJson<String, Id>(
    json['contest_id'],
    const IdConverter().fromJson,
  ),
  ownerAccountId: _$JsonConverterFromJson<String, Id>(
    json['owner_account_id'],
    const IdConverter().fromJson,
  ),
  publicationId: _$JsonConverterFromJson<String, Id>(
    json['publication_id'],
    const IdConverter().fromJson,
  ),
  action: $enumDecode(_$AuditActionEnumMap, json['action']),
  actorId: _$JsonConverterFromJson<String, Id>(
    json['actor_id'],
    const IdConverter().fromJson,
  ),
  authority: $enumDecode(_$AuthorityEnumMap, json['authority']),
  installationId: _$JsonConverterFromJson<String, Id>(
    json['installation_id'],
    const IdConverter().fromJson,
  ),
  device: json['device'] as String?,
  baseRevision: (json['base_revision'] as num?)?.toInt(),
  resultingRevision: (json['resulting_revision'] as num?)?.toInt(),
  serverTimestamp: const UtcTimestampConverter().fromJson(
    json['server_timestamp'] as String,
  ),
  clientTimestamp: _$JsonConverterFromJson<String, DateTime>(
    json['client_timestamp'],
    const UtcTimestampConverter().fromJson,
  ),
  reason: json['reason'] as String?,
  outcome:
      $enumDecodeNullable(_$AuditOutcomeEnumMap, json['outcome']) ??
      AuditOutcome.success,
);

Map<String, dynamic> _$AuditEventToJson(AuditEvent instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'entity_type': instance.entityType,
      'entity_id': const IdConverter().toJson(instance.entityId),
      'contest_id': _$JsonConverterToJson<String, Id>(
        instance.contestId,
        const IdConverter().toJson,
      ),
      'owner_account_id': _$JsonConverterToJson<String, Id>(
        instance.ownerAccountId,
        const IdConverter().toJson,
      ),
      'publication_id': _$JsonConverterToJson<String, Id>(
        instance.publicationId,
        const IdConverter().toJson,
      ),
      'action': _$AuditActionEnumMap[instance.action]!,
      'actor_id': _$JsonConverterToJson<String, Id>(
        instance.actorId,
        const IdConverter().toJson,
      ),
      'authority': _$AuthorityEnumMap[instance.authority]!,
      'installation_id': _$JsonConverterToJson<String, Id>(
        instance.installationId,
        const IdConverter().toJson,
      ),
      'device': instance.device,
      'base_revision': instance.baseRevision,
      'resulting_revision': instance.resultingRevision,
      'server_timestamp': const UtcTimestampConverter().toJson(
        instance.serverTimestamp,
      ),
      'client_timestamp': _$JsonConverterToJson<String, DateTime>(
        instance.clientTimestamp,
        const UtcTimestampConverter().toJson,
      ),
      'reason': instance.reason,
      'outcome': _$AuditOutcomeEnumMap[instance.outcome]!,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

const _$AuditActionEnumMap = {
  AuditAction.stateTransition: 'StateTransition',
  AuditAction.scoreAttempt: 'ScoreAttempt',
  AuditAction.scoreReview: 'ScoreReview',
  AuditAction.invitationIssued: 'InvitationIssued',
  AuditAction.invitationReplaced: 'InvitationReplaced',
  AuditAction.invitationRevoked: 'InvitationRevoked',
  AuditAction.invitationDeliveryRequested: 'InvitationDeliveryRequested',
  AuditAction.invitationAccessed: 'InvitationAccessed',
  AuditAction.invitationAccessFailed: 'InvitationAccessFailed',
  AuditAction.publicationAttempt: 'PublicationAttempt',
  AuditAction.delistRequested: 'DelistRequested',
  AuditAction.delistDecided: 'DelistDecided',
  AuditAction.delistWithdrawn: 'DelistWithdrawn',
  AuditAction.redaction: 'Redaction',
  AuditAction.conflict: 'Conflict',
  AuditAction.conflictAccepted: 'ConflictAccepted',
  AuditAction.conflictRejected: 'ConflictRejected',
  AuditAction.deletion: 'Deletion',
  AuditAction.restoration: 'Restoration',
  AuditAction.installationActivation: 'InstallationActivation',
};

const _$AuthorityEnumMap = {
  Authority.director: 'Director',
  Authority.participant: 'Participant',
  Authority.helper: 'Helper',
  Authority.system: 'System',
  Authority.administrator: 'Administrator',
};

const _$AuditOutcomeEnumMap = {
  AuditOutcome.success: 'Success',
  AuditOutcome.rejected: 'Rejected',
  AuditOutcome.conflict: 'Conflict',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
