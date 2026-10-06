// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_team_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateTeamRequest _$UpdateTeamRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UpdateTeamRequest', json, ($checkedConvert) {
      final val = UpdateTeamRequest(
        baseRevision: $checkedConvert(
          'base_revision',
          (v) => (v as num).toInt(),
        ),
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'baseRevision': 'base_revision'});

Map<String, dynamic> _$UpdateTeamRequestToJson(UpdateTeamRequest instance) =>
    <String, dynamic>{
      'base_revision': instance.baseRevision,
      'name': instance.name,
    };
