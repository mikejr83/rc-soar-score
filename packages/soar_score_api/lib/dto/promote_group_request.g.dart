// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promote_group_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromoteGroupRequest _$PromoteGroupRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PromoteGroupRequest', json, ($checkedConvert) {
      final val = PromoteGroupRequest(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => PromoteGroupItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PromoteGroupRequestToJson(
  PromoteGroupRequest instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};

PromoteGroupItem _$PromoteGroupItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PromoteGroupItem',
      json,
      ($checkedConvert) {
        final val = PromoteGroupItem(
          assignmentId: $checkedConvert('assignment_id', (v) => v as String),
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
        'assignmentId': 'assignment_id',
        'sourceAttemptId': 'source_attempt_id',
        'expectedScoreRevision': 'expected_score_revision',
      },
    );

Map<String, dynamic> _$PromoteGroupItemToJson(PromoteGroupItem instance) =>
    <String, dynamic>{
      'assignment_id': instance.assignmentId,
      'source_attempt_id': instance.sourceAttemptId,
      'expected_score_revision': instance.expectedScoreRevision,
    };
