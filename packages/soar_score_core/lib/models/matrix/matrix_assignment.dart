import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/assignment_type.dart';
import '../../enums/existing_score_handling.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'matrix_assignment.g.dart';

/// One pilot's flight in a group of a round.
///
/// Append-only: only `supersededByAssignmentId` is ever set afterwards, once,
/// when a move replaces the row. It has no row revision. See
/// `plan/data-model/entities/matrix_assignment.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class MatrixAssignment extends Equatable implements AppendOnly {
  MatrixAssignment({
    required this.id,
    required this.contestId,
    required this.matrixRevisionId,
    required this.contestParticipationId,
    required this.scheduledRoundId,
    required this.creditedRoundId,
    required this.group,
    this.lane,
    this.flightSequence = 1,
    required this.assignmentType,
    this.sourceAssignmentId,
    this.reFlightId,
    this.supersededByAssignmentId,
    required this.actorId,
    this.reason,
    this.existingScoreHandling = ExistingScoreHandling.none,
    this.resetScoreRevision,
    required DateTime createdAt,
  }) : createdAt = createdAt.toUtc() {
    requirePositive(group, 'group');
    if (lane != null) requirePositive(lane!, 'lane');
    requirePositive(flightSequence, 'flightSequence');
    if (supersededByAssignmentId == id) {
      throw ArgumentError('an assignment cannot supersede itself');
    }
    _checkType();
    final reset = existingScoreHandling == ExistingScoreHandling.reset;
    if (reset != (resetScoreRevision != null)) {
      throw ArgumentError(
        'reset_score_revision is set exactly when existing_score_handling '
        'is Reset',
      );
    }
    if (reset && assignmentType != AssignmentType.moved) {
      throw ArgumentError('only a Moved row can reset a score');
    }
    if (resetScoreRevision != null) {
      requireNonNegative(resetScoreRevision!, 'resetScoreRevision');
    }
  }

  factory MatrixAssignment.fromJson(Map<String, Object?> json) =>
      _$MatrixAssignmentFromJson(json);

  void _checkType() {
    final hasSource = sourceAssignmentId != null;
    switch (assignmentType) {
      case AssignmentType.original:
        if (hasSource || reFlightId != null) {
          throw ArgumentError('an Original row has no source or re-flight');
        }
        if (creditedRoundId != scheduledRoundId || flightSequence != 1) {
          throw ArgumentError(
            'an Original row is credited to its own round, sequence 1',
          );
        }
      case AssignmentType.lateAdd:
        if (hasSource || reFlightId != null) {
          throw ArgumentError('a LateAdd row has no source or re-flight');
        }
        if (flightSequence != 1) {
          throw ArgumentError('a LateAdd row has flight sequence 1');
        }
        requireNotBlank(reason ?? '', 'reason');
      case AssignmentType.moved:
        if (!hasSource || reFlightId != null) {
          throw ArgumentError('a Moved row has a source and no re-flight');
        }
        requireNotBlank(reason ?? '', 'reason');
      case AssignmentType.reflight:
        if (!hasSource || reFlightId == null) {
          throw ArgumentError('a Reflight row has a source and a re-flight');
        }
        requireNotBlank(reason ?? '', 'reason');
    }
  }

  @override
  final Id id;
  final Id contestId;

  /// The revision that contains the scheduled round.
  final Id matrixRevisionId;

  /// A pilot participation that has not retired.
  final Id contestParticipationId;

  /// The round the flight is flown in.
  final Id scheduledRoundId;

  /// The round the flight's score counts toward.
  final Id creditedRoundId;

  /// Group number within the scheduled round.
  final int group;

  /// Lane within the group; null when the lane mode is `None`.
  final int? lane;

  /// Flight sequence within the credited round; re-flights take the next.
  final int flightSequence;

  final AssignmentType assignmentType;

  /// The row a `Moved` or `Reflight` row replaces or re-flies.
  final Id? sourceAssignmentId;

  /// The re-flight that created a `Reflight` row.
  final Id? reFlightId;

  /// The `Moved` row that replaced this one; written once.
  final Id? supersededByAssignmentId;

  final Id actorId;
  final String? reason;
  final ExistingScoreHandling existingScoreHandling;

  /// The replaced placeholder's score revision, when a score was reset.
  final int? resetScoreRevision;

  final DateTime createdAt;

  bool get isSuperseded => supersededByAssignmentId != null;

  @override
  String get entityType => 'MatrixAssignment';

  @override
  SyncScope get syncScope => SyncScope.contest;

  Map<String, Object?> toJson() => _$MatrixAssignmentToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    matrixRevisionId,
    contestParticipationId,
    scheduledRoundId,
    creditedRoundId,
    group,
    lane,
    flightSequence,
    assignmentType,
    sourceAssignmentId,
    reFlightId,
    supersededByAssignmentId,
    actorId,
    reason,
    existingScoreHandling,
    resetScoreRevision,
    createdAt,
  ];
}
