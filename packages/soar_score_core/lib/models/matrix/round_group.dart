import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/group_status.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'round_group.g.dart';

/// A group within a round, which can be locked on its own.
///
/// See `plan/data-model/entities/round_group.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class RoundGroup extends Equatable implements Synchronizable {
  RoundGroup({
    required this.id,
    required this.contestId,
    required this.roundId,
    required this.groupNumber,
    this.status = GroupStatus.open,
    this.lockedBy,
    DateTime? lockedAt,
    this.revision = 0,
  }) : lockedAt = lockedAt?.toUtc() {
    requirePositive(groupNumber, 'groupNumber');
    final locked = status == GroupStatus.locked;
    if (locked != (lockedBy != null) || locked != (lockedAt != null)) {
      throw ArgumentError(
        'locked_by and locked_at are set exactly when the group is Locked',
      );
    }
    requireNonNegative(revision, 'revision');
  }

  factory RoundGroup.fromJson(Map<String, Object?> json) =>
      _$RoundGroupFromJson(json);

  @override
  final Id id;
  final Id contestId;
  final Id roundId;

  /// Group number within the round, from 1.
  final int groupNumber;

  final GroupStatus status;
  final Id? lockedBy;
  final DateTime? lockedAt;

  @override
  final int revision;

  bool get isLocked => status == GroupStatus.locked;

  @override
  String get entityType => 'RoundGroup';

  @override
  SyncScope get syncScope => SyncScope.contest;

  Map<String, Object?> toJson() => _$RoundGroupToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    roundId,
    groupNumber,
    status,
    lockedBy,
    lockedAt,
    revision,
  ];
}
