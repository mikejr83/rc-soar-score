// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_team_member_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddTeamMemberRequest _$AddTeamMemberRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'AddTeamMemberRequest',
  json,
  ($checkedConvert) {
    final val = AddTeamMemberRequest(
      id: $checkedConvert(
        'id',
        (v) => const IdConverter().fromJson(v as String),
      ),
      teamId: $checkedConvert(
        'team_id',
        (v) => const IdConverter().fromJson(v as String),
      ),
      contestParticipationId: $checkedConvert(
        'contest_participation_id',
        (v) => const IdConverter().fromJson(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'teamId': 'team_id',
    'contestParticipationId': 'contest_participation_id',
  },
);

Map<String, dynamic> _$AddTeamMemberRequestToJson(
  AddTeamMemberRequest instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'team_id': const IdConverter().toJson(instance.teamId),
  'contest_participation_id': const IdConverter().toJson(
    instance.contestParticipationId,
  ),
};
