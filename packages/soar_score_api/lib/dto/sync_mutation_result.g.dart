// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_mutation_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncMutationResult _$SyncMutationResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SyncMutationResult',
      json,
      ($checkedConvert) {
        final val = SyncMutationResult(
          clientMutationId: $checkedConvert(
            'client_mutation_id',
            (v) => v as String,
          ),
          outcome: $checkedConvert(
            'outcome',
            (v) => $enumDecode(_$MutationOutcomeEnumMap, v),
          ),
          revision: $checkedConvert('revision', (v) => (v as num?)?.toInt()),
          sequence: $checkedConvert('sequence', (v) => (v as num?)?.toInt()),
          reasonCode: $checkedConvert('reason_code', (v) => v as String?),
          currentRevision: $checkedConvert(
            'current_revision',
            (v) => (v as num?)?.toInt(),
          ),
          dependsOn: $checkedConvert('depends_on', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'clientMutationId': 'client_mutation_id',
        'reasonCode': 'reason_code',
        'currentRevision': 'current_revision',
        'dependsOn': 'depends_on',
      },
    );

Map<String, dynamic> _$SyncMutationResultToJson(SyncMutationResult instance) =>
    <String, dynamic>{
      'client_mutation_id': instance.clientMutationId,
      'outcome': _$MutationOutcomeEnumMap[instance.outcome]!,
      'revision': instance.revision,
      'sequence': instance.sequence,
      'reason_code': instance.reasonCode,
      'current_revision': instance.currentRevision,
      'depends_on': instance.dependsOn,
    };

const _$MutationOutcomeEnumMap = {
  MutationOutcome.pending: 'Pending',
  MutationOutcome.accepted: 'Accepted',
  MutationOutcome.rejected: 'Rejected',
  MutationOutcome.conflict: 'Conflict',
  MutationOutcome.skipped: 'Skipped',
};
