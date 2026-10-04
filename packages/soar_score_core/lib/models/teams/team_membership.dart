import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../id.dart';
import '../shared/shared.dart';

part 'team_membership.g.dart';

/// Links a team to a contest participation.
///
/// `contestId` is denormalized for sync scoping. See
/// `plan/data-model/entities/team_membership.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class TeamMembership extends Equatable implements Synchronizable {
  TeamMembership({
    required this.id,
    required this.teamId,
    required this.contestParticipationId,
    required this.contestId,
    this.revision = 0,
  }) {
    requireNonNegative(revision, 'revision');
  }

  factory TeamMembership.fromJson(Map<String, Object?> json) =>
      _$TeamMembershipFromJson(json);

  @override
  final Id id;
  final Id teamId;
  final Id contestParticipationId;
  final Id contestId;

  @override
  final int revision;

  @override
  String get entityType => 'TeamMembership';

  @override
  SyncScope get syncScope => SyncScope.contest;

  Map<String, Object?> toJson() => _$TeamMembershipToJson(this);

  @override
  List<Object?> get props => [
    id,
    teamId,
    contestParticipationId,
    contestId,
    revision,
  ];
}
