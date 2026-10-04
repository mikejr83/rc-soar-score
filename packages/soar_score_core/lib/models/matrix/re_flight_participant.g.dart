// GENERATED CODE - DO NOT MODIFY BY HAND

part of 're_flight_participant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReFlightParticipant _$ReFlightParticipantFromJson(Map<String, dynamic> json) =>
    ReFlightParticipant(
      id: const IdConverter().fromJson(json['id'] as String),
      contestId: const IdConverter().fromJson(json['contest_id'] as String),
      reFlightId: const IdConverter().fromJson(json['re_flight_id'] as String),
      contestParticipationId: const IdConverter().fromJson(
        json['contest_participation_id'] as String,
      ),
      role: $enumDecode(_$ReFlightParticipantRoleEnumMap, json['role']),
      excludedReason: $enumDecodeNullable(
        _$ExcludedReasonEnumMap,
        json['excluded_reason'],
      ),
      drawPosition: (json['draw_position'] as num?)?.toInt(),
      response:
          $enumDecodeNullable(_$ReFlightResponseEnumMap, json['response']) ??
          ReFlightResponse.notRequired,
      respondedBy: $enumDecodeNullable(
        _$ResponseActorEnumMap,
        json['responded_by'],
      ),
      respondedAt: _$JsonConverterFromJson<String, DateTime>(
        json['responded_at'],
        const UtcTimestampConverter().fromJson,
      ),
      notificationState:
          $enumDecodeNullable(
            _$NotificationStateEnumMap,
            json['notification_state'],
          ) ??
          NotificationState.notRequired,
      notifiedAt: _$JsonConverterFromJson<String, DateTime>(
        json['notified_at'],
        const UtcTimestampConverter().fromJson,
      ),
      acknowledgedAt: _$JsonConverterFromJson<String, DateTime>(
        json['acknowledged_at'],
        const UtcTimestampConverter().fromJson,
      ),
      assignmentId: _$JsonConverterFromJson<String, Id>(
        json['assignment_id'],
        const IdConverter().fromJson,
      ),
      revision: (json['revision'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ReFlightParticipantToJson(
  ReFlightParticipant instance,
) => <String, dynamic>{
  'id': const IdConverter().toJson(instance.id),
  'contest_id': const IdConverter().toJson(instance.contestId),
  're_flight_id': const IdConverter().toJson(instance.reFlightId),
  'contest_participation_id': const IdConverter().toJson(
    instance.contestParticipationId,
  ),
  'role': _$ReFlightParticipantRoleEnumMap[instance.role]!,
  'excluded_reason': _$ExcludedReasonEnumMap[instance.excludedReason],
  'draw_position': instance.drawPosition,
  'response': _$ReFlightResponseEnumMap[instance.response]!,
  'responded_by': _$ResponseActorEnumMap[instance.respondedBy],
  'responded_at': _$JsonConverterToJson<String, DateTime>(
    instance.respondedAt,
    const UtcTimestampConverter().toJson,
  ),
  'notification_state': _$NotificationStateEnumMap[instance.notificationState]!,
  'notified_at': _$JsonConverterToJson<String, DateTime>(
    instance.notifiedAt,
    const UtcTimestampConverter().toJson,
  ),
  'acknowledged_at': _$JsonConverterToJson<String, DateTime>(
    instance.acknowledgedAt,
    const UtcTimestampConverter().toJson,
  ),
  'assignment_id': _$JsonConverterToJson<String, Id>(
    instance.assignmentId,
    const IdConverter().toJson,
  ),
  'revision': instance.revision,
};

const _$ReFlightParticipantRoleEnumMap = {
  ReFlightParticipantRole.awarded: 'Awarded',
  ReFlightParticipantRole.drawn: 'Drawn',
  ReFlightParticipantRole.groupMember: 'GroupMember',
  ReFlightParticipantRole.candidate: 'Candidate',
  ReFlightParticipantRole.excluded: 'Excluded',
};

const _$ExcludedReasonEnumMap = {
  ExcludedReason.sameTeam: 'SameTeam',
  ExcludedReason.retired: 'Retired',
  ExcludedReason.notEligible: 'NotEligible',
  ExcludedReason.directorExcluded: 'DirectorExcluded',
  ExcludedReason.declined: 'Declined',
};

const _$ReFlightResponseEnumMap = {
  ReFlightResponse.notRequired: 'NotRequired',
  ReFlightResponse.pending: 'Pending',
  ReFlightResponse.accepted: 'Accepted',
  ReFlightResponse.declined: 'Declined',
};

const _$ResponseActorEnumMap = {
  ResponseActor.participant: 'Participant',
  ResponseActor.director: 'Director',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

const _$NotificationStateEnumMap = {
  NotificationState.notRequired: 'NotRequired',
  NotificationState.pending: 'Pending',
  NotificationState.delivered: 'Delivered',
  NotificationState.failed: 'Failed',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
