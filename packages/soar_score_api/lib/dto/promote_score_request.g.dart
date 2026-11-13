// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promote_score_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromoteScoreRequest _$PromoteScoreRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PromoteScoreRequest',
      json,
      ($checkedConvert) {
        final val = PromoteScoreRequest(
          sourceAttemptId: $checkedConvert(
            'source_attempt_id',
            (v) => v as String,
          ),
          expectedScoreRevision: $checkedConvert(
            'expected_score_revision',
            (v) => wholeNumber(v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'sourceAttemptId': 'source_attempt_id',
        'expectedScoreRevision': 'expected_score_revision',
      },
    );

Map<String, dynamic> _$PromoteScoreRequestToJson(
  PromoteScoreRequest instance,
) => <String, dynamic>{
  'source_attempt_id': instance.sourceAttemptId,
  'expected_score_revision': instance.expectedScoreRevision,
};
