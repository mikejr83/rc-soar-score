// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contest_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContestScoringConfig _$ContestScoringConfigFromJson(
  Map<String, dynamic> json,
) => ContestScoringConfig(
  discipline: $enumDecode(_$DisciplineEnumMap, json['discipline']),
  targetTimeSeconds: (json['targetTimeSeconds'] as num).toDouble(),
  fractionalSeconds: (json['fractionalSeconds'] as num?)?.toInt() ?? 0,
  pointsPerSecond: (json['pointsPerSecond'] as num?)?.toDouble() ?? 1.0,
  groupScoreType:
      $enumDecodeNullable(_$GroupScoreTypeEnumMap, json['groupScoreType']) ??
      GroupScoreType.normalized,
  totalScoreRounding:
      $enumDecodeNullable(
        _$TotalScoreRoundingEnumMap,
        json['totalScoreRounding'],
      ) ??
      TotalScoreRounding.round1,
  droppedRounds: (json['droppedRounds'] as num?)?.toInt(),
  useTeams: json['useTeams'] as bool? ?? false,
  f3jWorkingTimeSeconds: (json['f3jWorkingTimeSeconds'] as num?)?.toInt(),
  f5jWorkingTimeSeconds: (json['f5jWorkingTimeSeconds'] as num?)?.toInt(),
  f5jMotorRestart: $enumDecodeNullable(
    _$MotorRestartModeEnumMap,
    json['f5jMotorRestart'],
  ),
  f5jHeightPenaltyPerMeter: (json['f5jHeightPenaltyPerMeter'] as num?)
      ?.toDouble(),
  f5jReferenceAltitudeMeters: (json['f5jReferenceAltitudeMeters'] as num?)
      ?.toDouble(),
  f5jAboveReferencePenaltyPerMeter:
      (json['f5jAboveReferencePenaltyPerMeter'] as num?)?.toDouble(),
  f3kTaskType: $enumDecodeNullable(_$F3kTaskTypeEnumMap, json['f3kTaskType']),
);

Map<String, dynamic> _$ContestScoringConfigToJson(
  ContestScoringConfig instance,
) => <String, dynamic>{
  'discipline': _$DisciplineEnumMap[instance.discipline]!,
  'targetTimeSeconds': instance.targetTimeSeconds,
  'fractionalSeconds': instance.fractionalSeconds,
  'pointsPerSecond': instance.pointsPerSecond,
  'groupScoreType': _$GroupScoreTypeEnumMap[instance.groupScoreType]!,
  'totalScoreRounding':
      _$TotalScoreRoundingEnumMap[instance.totalScoreRounding]!,
  'droppedRounds': instance.droppedRounds,
  'useTeams': instance.useTeams,
  'f3jWorkingTimeSeconds': instance.f3jWorkingTimeSeconds,
  'f5jWorkingTimeSeconds': instance.f5jWorkingTimeSeconds,
  'f5jMotorRestart': _$MotorRestartModeEnumMap[instance.f5jMotorRestart],
  'f5jHeightPenaltyPerMeter': instance.f5jHeightPenaltyPerMeter,
  'f5jReferenceAltitudeMeters': instance.f5jReferenceAltitudeMeters,
  'f5jAboveReferencePenaltyPerMeter': instance.f5jAboveReferencePenaltyPerMeter,
  'f3kTaskType': _$F3kTaskTypeEnumMap[instance.f3kTaskType],
};

const _$DisciplineEnumMap = {
  Discipline.ales: 'ales',
  Discipline.thermalDuration: 'thermalDuration',
  Discipline.f3j: 'f3j',
  Discipline.f5j: 'f5j',
  Discipline.f3k: 'f3k',
};

const _$GroupScoreTypeEnumMap = {
  GroupScoreType.time: 'time',
  GroupScoreType.normalized: 'normalized',
};

const _$TotalScoreRoundingEnumMap = {
  TotalScoreRounding.truncate0: 'truncate0',
  TotalScoreRounding.truncate1: 'truncate1',
  TotalScoreRounding.truncate2: 'truncate2',
  TotalScoreRounding.truncate3: 'truncate3',
  TotalScoreRounding.round0: 'round0',
  TotalScoreRounding.round1: 'round1',
  TotalScoreRounding.round2: 'round2',
  TotalScoreRounding.round3: 'round3',
};

const _$MotorRestartModeEnumMap = {
  MotorRestartMode.allowed: 'allowed',
  MotorRestartMode.nonDroppableZero: 'nonDroppableZero',
  MotorRestartMode.notAllowed: 'notAllowed',
};

const _$F3kTaskTypeEnumMap = {
  F3kTaskType.taskA: 'taskA',
  F3kTaskType.taskB: 'taskB',
  F3kTaskType.taskC: 'taskC',
  F3kTaskType.taskD: 'taskD',
  F3kTaskType.taskE: 'taskE',
  F3kTaskType.taskF: 'taskF',
  F3kTaskType.taskG: 'taskG',
  F3kTaskType.taskH: 'taskH',
  F3kTaskType.taskI: 'taskI',
  F3kTaskType.taskJ: 'taskJ',
  F3kTaskType.taskK: 'taskK',
  F3kTaskType.taskL: 'taskL',
  F3kTaskType.taskM: 'taskM',
  F3kTaskType.taskN: 'taskN',
};
