// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_membership.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeamMembership _$TeamMembershipFromJson(Map<String, dynamic> json) =>
    TeamMembership(
      id: const IdConverter().fromJson(json['id'] as String),
      teamId: const IdConverter().fromJson(json['team_id'] as String),
      contestParticipationId: const IdConverter().fromJson(
        json['contest_participation_id'] as String,
      ),
      contestId: const IdConverter().fromJson(json['contest_id'] as String),
      revision: (json['revision'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$TeamMembershipToJson(TeamMembership instance) =>
    <String, dynamic>{
      'id': const IdConverter().toJson(instance.id),
      'team_id': const IdConverter().toJson(instance.teamId),
      'contest_participation_id': const IdConverter().toJson(
        instance.contestParticipationId,
      ),
      'contest_id': const IdConverter().toJson(instance.contestId),
      'revision': instance.revision,
    };
