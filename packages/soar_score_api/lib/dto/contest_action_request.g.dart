// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contest_action_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContestActionRequest _$ContestActionRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ContestActionRequest', json, ($checkedConvert) {
  final val = ContestActionRequest(
    action: $checkedConvert(
      'action',
      (v) => $enumDecode(_$ContestActionEnumMap, v),
    ),
    baseRevision: $checkedConvert('base_revision', (v) => (v as num).toInt()),
  );
  return val;
}, fieldKeyMap: const {'baseRevision': 'base_revision'});

Map<String, dynamic> _$ContestActionRequestToJson(
  ContestActionRequest instance,
) => <String, dynamic>{
  'action': _$ContestActionEnumMap[instance.action]!,
  'base_revision': instance.baseRevision,
};

const _$ContestActionEnumMap = {
  ContestAction.complete: 'complete',
  ContestAction.openScoring: 'openScoring',
  ContestAction.closeScoring: 'closeScoring',
  ContestAction.lock: 'lock',
  ContestAction.unlock: 'unlock',
  ContestAction.hideResults: 'hideResults',
  ContestAction.showResults: 'showResults',
};
