// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_team_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateTeamRequest _$CreateTeamRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateTeamRequest', json, ($checkedConvert) {
      final val = CreateTeamRequest(
        id: $checkedConvert(
          'id',
          (v) => const IdConverter().fromJson(v as String),
        ),
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$CreateTeamRequestToJson(CreateTeamRequest instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'name': instance.name,
    };
