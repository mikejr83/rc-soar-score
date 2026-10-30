// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_event_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditEventDto _$AuditEventDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AuditEventDto',
      json,
      ($checkedConvert) {
        final val = AuditEventDto(
          id: $checkedConvert(
            'id',
            (v) => const IdConverter().fromJson(v as String),
          ),
          entityType: $checkedConvert('entity_type', (v) => v as String),
          entityId: $checkedConvert(
            'entity_id',
            (v) => const IdConverter().fromJson(v as String),
          ),
          action: $checkedConvert(
            'action',
            (v) => $enumDecode(_$AuditActionEnumMap, v),
          ),
          authority: $checkedConvert(
            'authority',
            (v) => $enumDecode(_$AuthorityEnumMap, v),
          ),
          serverTimestamp: $checkedConvert(
            'server_timestamp',
            (v) => const UtcTimestampConverter().fromJson(v as String),
          ),
          outcome: $checkedConvert(
            'outcome',
            (v) => $enumDecode(_$AuditOutcomeEnumMap, v),
          ),
          transition: $checkedConvert(
            'transition',
            (v) => $enumDecodeNullable(_$ContestActionEnumMap, v),
          ),
          actorId: $checkedConvert(
            'actor_id',
            (v) => _$JsonConverterFromJson<String, Id>(
              v,
              const IdConverter().fromJson,
            ),
          ),
          baseRevision: $checkedConvert(
            'base_revision',
            (v) => (v as num?)?.toInt(),
          ),
          resultingRevision: $checkedConvert(
            'resulting_revision',
            (v) => (v as num?)?.toInt(),
          ),
          reason: $checkedConvert('reason', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'entityType': 'entity_type',
        'entityId': 'entity_id',
        'serverTimestamp': 'server_timestamp',
        'actorId': 'actor_id',
        'baseRevision': 'base_revision',
        'resultingRevision': 'resulting_revision',
      },
    );

Map<String, dynamic> _$AuditEventDtoToJson(AuditEventDto instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'entity_type': instance.entityType,
      'entity_id': const IdConverter().toJson(instance.entityId),
      'action': _$AuditActionEnumMap[instance.action]!,
      'transition': _$ContestActionEnumMap[instance.transition],
      'actor_id': _$JsonConverterToJson<String, Id>(
        instance.actorId,
        const IdConverter().toJson,
      ),
      'authority': _$AuthorityEnumMap[instance.authority]!,
      'base_revision': instance.baseRevision,
      'resulting_revision': instance.resultingRevision,
      'server_timestamp': const UtcTimestampConverter().toJson(
        instance.serverTimestamp,
      ),
      'reason': instance.reason,
      'outcome': _$AuditOutcomeEnumMap[instance.outcome]!,
    };

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
  AuditAction.configurationSaved: 'ConfigurationSaved',
  AuditAction.matrixDrawn: 'MatrixDrawn',
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

const _$ContestActionEnumMap = {
  ContestAction.complete: 'complete',
  ContestAction.openScoring: 'openScoring',
  ContestAction.closeScoring: 'closeScoring',
  ContestAction.lock: 'lock',
  ContestAction.unlock: 'unlock',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
