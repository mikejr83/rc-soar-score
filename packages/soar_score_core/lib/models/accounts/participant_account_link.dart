import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/participant_link_origin.dart';
import '../../enums/participant_link_status.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'participant_account_link.g.dart';

/// Relates a director's participant profile to the account of the person it
/// describes.
///
/// Backend only. It never shares the profile. See
/// `plan/data-model/entities/participant_account_link.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class ParticipantAccountLink extends Equatable implements BackendOnly {
  ParticipantAccountLink({
    required this.id,
    required this.participantProfileId,
    required this.accountId,
    required this.status,
    required this.origin,
    required DateTime createdAt,
    DateTime? confirmedAt,
    DateTime? endedAt,
    this.revision = 0,
  }) : createdAt = createdAt.toUtc(),
       confirmedAt = confirmedAt?.toUtc(),
       endedAt = endedAt?.toUtc() {
    if (status == ParticipantLinkStatus.candidate && confirmedAt != null) {
      throw ArgumentError('a Candidate link is not yet confirmed');
    }
    if (status == ParticipantLinkStatus.confirmed && confirmedAt == null) {
      throw ArgumentError('a Confirmed link records when it was confirmed');
    }
    if ((status == ParticipantLinkStatus.ended) != (endedAt != null)) {
      throw ArgumentError('ended_at is set exactly when the link has Ended');
    }
    if (origin == ParticipantLinkOrigin.directoryPull &&
        status == ParticipantLinkStatus.candidate) {
      throw ArgumentError('a DirectoryPull link is confirmed on creation');
    }
    requireNonNegative(revision, 'revision');
  }

  factory ParticipantAccountLink.fromJson(Map<String, Object?> json) =>
      _$ParticipantAccountLinkFromJson(json);

  final Id id;
  final Id participantProfileId;
  final Id accountId;
  final ParticipantLinkStatus status;
  final ParticipantLinkOrigin origin;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? endedAt;
  final int revision;

  bool get isConfirmed => status == ParticipantLinkStatus.confirmed;

  Map<String, Object?> toJson() => _$ParticipantAccountLinkToJson(this);

  @override
  List<Object?> get props => [
    id,
    participantProfileId,
    accountId,
    status,
    origin,
    createdAt,
    confirmedAt,
    endedAt,
    revision,
  ];
}
