// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resolve_conflict_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResolveConflictRequest _$ResolveConflictRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ResolveConflictRequest', json, ($checkedConvert) {
  final val = ResolveConflictRequest(
    clientMutationId: $checkedConvert('client_mutation_id', (v) => v as String),
    choice: $checkedConvert(
      'choice',
      (v) => $enumDecode(_$ConflictResolutionChoiceEnumMap, v),
    ),
    payload: $checkedConvert('payload', (v) => v as Map<String, dynamic>?),
  );
  return val;
}, fieldKeyMap: const {'clientMutationId': 'client_mutation_id'});

Map<String, dynamic> _$ResolveConflictRequestToJson(
  ResolveConflictRequest instance,
) => <String, dynamic>{
  'client_mutation_id': instance.clientMutationId,
  'choice': _$ConflictResolutionChoiceEnumMap[instance.choice]!,
  'payload': ?instance.payload,
};

const _$ConflictResolutionChoiceEnumMap = {
  ConflictResolutionChoice.keptAccepted: 'KeptAccepted',
  ConflictResolutionChoice.tookCompeting: 'TookCompeting',
  ConflictResolutionChoice.merged: 'Merged',
};
