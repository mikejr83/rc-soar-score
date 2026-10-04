import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/excluded_reason.dart';
import '../../enums/notification_state.dart';
import '../../enums/re_flight_participant_role.dart';
import '../../enums/re_flight_response.dart';
import '../../enums/response_actor.dart';
import '../id.dart';
import '../shared/shared.dart';

part 're_flight_participant.g.dart';

/// A pilot's part in a re-flight: role, draw position, response and
/// notification.
///
/// See `plan/data-model/entities/re_flight_participant.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class ReFlightParticipant extends Equatable implements Synchronizable {
  ReFlightParticipant({
    required this.id,
    required this.contestId,
    required this.reFlightId,
    required this.contestParticipationId,
    required this.role,
    this.excludedReason,
    this.drawPosition,
    this.response = ReFlightResponse.notRequired,
    this.respondedBy,
    DateTime? respondedAt,
    this.notificationState = NotificationState.notRequired,
    DateTime? notifiedAt,
    DateTime? acknowledgedAt,
    this.assignmentId,
    this.revision = 0,
  }) : respondedAt = respondedAt?.toUtc(),
       notifiedAt = notifiedAt?.toUtc(),
       acknowledgedAt = acknowledgedAt?.toUtc() {
    final excluded = role == ReFlightParticipantRole.excluded;
    if (excluded != (excludedReason != null)) {
      throw ArgumentError('excluded_reason is set exactly when Excluded');
    }
    if (drawPosition != null) requirePositive(drawPosition!, 'drawPosition');
    if (role == ReFlightParticipantRole.groupMember &&
        response != ReFlightResponse.notRequired) {
      throw ArgumentError('a GroupMember has no response to give');
    }
    if (assignmentId != null &&
        (excluded || role == ReFlightParticipantRole.candidate)) {
      throw ArgumentError('only pilots who fly have an assignment');
    }
    requireNonNegative(revision, 'revision');
  }

  factory ReFlightParticipant.fromJson(Map<String, Object?> json) =>
      _$ReFlightParticipantFromJson(json);

  @override
  final Id id;
  final Id contestId;
  final Id reFlightId;
  final Id contestParticipationId;
  final ReFlightParticipantRole role;
  final ExcludedReason? excludedReason;

  /// The order the pilot was drawn in, from 1.
  final int? drawPosition;

  final ReFlightResponse response;
  final ResponseActor? respondedBy;
  final DateTime? respondedAt;
  final NotificationState notificationState;
  final DateTime? notifiedAt;
  final DateTime? acknowledgedAt;

  /// The `Reflight` assignment created when the group was finalized.
  final Id? assignmentId;

  @override
  final int revision;

  @override
  String get entityType => 'ReFlightParticipant';

  @override
  SyncScope get syncScope => SyncScope.contest;

  Map<String, Object?> toJson() => _$ReFlightParticipantToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    reFlightId,
    contestParticipationId,
    role,
    excludedReason,
    drawPosition,
    response,
    respondedBy,
    respondedAt,
    notificationState,
    notifiedAt,
    acknowledgedAt,
    assignmentId,
    revision,
  ];
}
