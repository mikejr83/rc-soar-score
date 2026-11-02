// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enter_scores_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnterScoresRequest _$EnterScoresRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EnterScoresRequest', json, ($checkedConvert) {
      final val = EnterScoresRequest(
        entries: $checkedConvert(
          'entries',
          (v) => (v as List<dynamic>)
              .map((e) => EnterScoresEntry.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$EnterScoresRequestToJson(EnterScoresRequest instance) =>
    <String, dynamic>{
      'entries': instance.entries.map((e) => e.toJson()).toList(),
    };

EnterScoresEntry _$EnterScoresEntryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'EnterScoresEntry',
      json,
      ($checkedConvert) {
        final val = EnterScoresEntry(
          assignmentId: $checkedConvert(
            'assignment_id',
            (v) => const IdConverter().fromJson(v as String),
          ),
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
        'assignmentId': 'assignment_id',
        'clientMutationId': 'client_mutation_id',
        'baseScoreRevision': 'base_score_revision',
      },
    );

Map<String, dynamic> _$EnterScoresEntryToJson(EnterScoresEntry instance) =>
    <String, dynamic>{
      'assignment_id': const IdConverter().toJson(instance.assignmentId),
      'client_mutation_id': instance.clientMutationId,
      'base_score_revision': instance.baseScoreRevision,
      'components': instance.components,
      'reason': instance.reason,
    };
