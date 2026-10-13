import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/role_type.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'contest_participation.g.dart';

/// A person's place in one contest: role, number and scoring identifier.
///
/// Holds no identity details; they are read from the profile. See
/// `plan/data-model/entities/contest_participation.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
@ScoringUuidConverter()
class ContestParticipation extends Equatable implements Synchronizable {
  ContestParticipation({
    required this.id,
    required this.contestId,
    required this.participantProfileId,
    this.classification,
    required this.roleId,
    required String roleName,
    this.roleType = RoleType.pilot,
    this.participantNumber,
    required this.scoringUuid,
    this.retiredAtRound,
    this.revision = 0,
  }) : roleName = requireNotBlank(roleName, 'roleName') {
    if (roleType != RoleType.pilot) {
      if (classification != null) {
        throw ArgumentError('only pilots have a classification');
      }
      if (retiredAtRound != null) {
        throw ArgumentError('only pilots can retire');
      }
    }
    if (retiredAtRound != null && retiredAtRound! < 1) {
      throw ArgumentError.value(
        retiredAtRound,
        'retiredAtRound',
        'must be at least 1',
      );
    }
    if (participantNumber != null) {
      requireNonNegative(participantNumber!, 'participantNumber');
    }
    requireNonNegative(revision, 'revision');
  }

  factory ContestParticipation.fromJson(Map<String, Object?> json) =>
      _$ContestParticipationFromJson(json);

  @override
  final Id id;
  final Id contestId;
  final Id participantProfileId;

  /// Free-text class label, for pilots only.
  final String? classification;

  final Id roleId;

  /// The role's name when it was assigned; never follows renames.
  final String roleName;

  /// The role's type when it was assigned; the authority on whether this
  /// participant flies.
  final RoleType roleType;

  /// One running number per contest; null until allocated.
  final int? participantNumber;

  /// The public scoring identifier, a random UUIDv4.
  final ScoringUuid scoringUuid;

  /// The round a pilot retired from; null while they have not retired.
  final int? retiredAtRound;

  @override
  final int revision;

  /// This participation with [number] as its participant number.
  ContestParticipation withParticipantNumber(int number) =>
      ContestParticipation(
        id: id,
        contestId: contestId,
        participantProfileId: participantProfileId,
        classification: classification,
        roleId: roleId,
        roleName: roleName,
        roleType: roleType,
        participantNumber: number,
        scoringUuid: scoringUuid,
        retiredAtRound: retiredAtRound,
        revision: revision,
      );

  bool get isPilot => roleType == RoleType.pilot;
  bool get isRetired => retiredAtRound != null;

  /// True when this pilot retired at or before round [roundOrdinal], so no
  /// flight of that round is expected from them.
  bool hasRetiredBy(int roundOrdinal) =>
      retiredAtRound != null && retiredAtRound! <= roundOrdinal;

  @override
  String get entityType => 'ContestParticipation';

  @override
  SyncScope get syncScope => SyncScope.contest;

  Map<String, Object?> toJson() => _$ContestParticipationToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    participantProfileId,
    classification,
    roleId,
    roleName,
    roleType,
    participantNumber,
    scoringUuid,
    retiredAtRound,
    revision,
  ];
}
