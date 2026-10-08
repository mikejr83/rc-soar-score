// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enter_score_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnterScoreRequest _$EnterScoreRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'EnterScoreRequest',
      json,
      ($checkedConvert) {
        final val = EnterScoreRequest(
          clientMutationId: $checkedConvert(
            'client_mutation_id',
            (v) => v as String,
          ),
          baseScoreRevision: $checkedConvert(
            'base_score_revision',
            (v) => (v as num).toInt(),
          ),
          components: $checkedConvert(
            'components',
            (v) => v as Map<String, dynamic>,
          ),
          reason: $checkedConvert('reason', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'clientMutationId': 'client_mutation_id',
        'baseScoreRevision': 'base_score_revision',
      },
    );

Map<String, dynamic> _$EnterScoreRequestToJson(EnterScoreRequest instance) =>
    <String, dynamic>{
      'client_mutation_id': instance.clientMutationId,
      'base_score_revision': instance.baseScoreRevision,
      'components': instance.components,
      'reason': instance.reason,
    };
