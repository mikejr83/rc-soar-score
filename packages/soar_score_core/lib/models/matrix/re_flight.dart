import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/re_flight_status.dart';
import '../../enums/re_flight_type.dart';
import '../id.dart';
import '../shared/shared.dart';

part 're_flight.g.dart';

/// An extra chance awarded for a flight, and how it is being arranged.
///
/// The original flight is never overwritten. See
/// `plan/data-model/entities/re_flight.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class ReFlight extends Equatable implements Synchronizable {
  ReFlight({
    required this.id,
    required this.contestId,
    required this.creditedRoundId,
    required this.sourceRoundId,
    required this.sourceGroup,
    required this.type,
    this.sequence = 1,
    this.previousReflightId,
    this.status = ReFlightStatus.proposed,
    required String reason,
    required this.scheduledRoundId,
    required this.flownGroup,
    this.deviationAcknowledged = false,
    this.requestedGroupSize,
    this.achievableMaxSize,
    this.sizeExceptionConfirmed = false,
    this.randomSeed,
    this.algorithmVersion,
    required this.configRevisionId,
    required this.createdBy,
    required DateTime createdAt,
    this.groupFinalizedBy,
    DateTime? groupFinalizedAt,
    this.finalizedBy,
    DateTime? finalizedAt,
    this.cancelledBy,
    DateTime? cancelledAt,
    this.cancelReason,
    this.revision = 0,
  }) : reason = requireNotBlank(reason, 'reason'),
       createdAt = createdAt.toUtc(),
       groupFinalizedAt = groupFinalizedAt?.toUtc(),
       finalizedAt = finalizedAt?.toUtc(),
       cancelledAt = cancelledAt?.toUtc() {
    requirePositive(sourceGroup, 'sourceGroup');
    requirePositive(sequence, 'sequence');
    requirePositive(flownGroup, 'flownGroup');
    if (previousReflightId == id) {
      throw ArgumentError('a re-flight cannot follow itself');
    }
    if (type != ReFlightType.randomDraw &&
        (requestedGroupSize != null ||
            achievableMaxSize != null ||
            randomSeed != null ||
            algorithmVersion != null)) {
      throw ArgumentError('draw fields belong to a RandomDraw re-flight');
    }
    if (requestedGroupSize != null) {
      requirePositive(requestedGroupSize!, 'requestedGroupSize');
    }
    if (achievableMaxSize != null) {
      requirePositive(achievableMaxSize!, 'achievableMaxSize');
    }
    if (randomSeed != null) requireSeed(randomSeed!, 'randomSeed');
    _checkOutcome();
    requireNonNegative(revision, 'revision');
  }

  factory ReFlight.fromJson(Map<String, Object?> json) =>
      _$ReFlightFromJson(json);

  void _checkOutcome() {
    if ((groupFinalizedBy == null) != (groupFinalizedAt == null)) {
      throw ArgumentError(
        'group_finalized_by and group_finalized_at are set together',
      );
    }
    final groupDone =
        status == ReFlightStatus.readyToFly ||
        status == ReFlightStatus.finalized;
    if (groupDone && groupFinalizedAt == null) {
      throw ArgumentError('the group is finalized once the status is ');
    }
    final finalized = status == ReFlightStatus.finalized;
    if (finalized != (finalizedBy != null) ||
        finalized != (finalizedAt != null)) {
      throw ArgumentError(
        'finalized_by and finalized_at are set exactly when Finalized',
      );
    }
    final cancelled = status == ReFlightStatus.cancelled;
    if (cancelled != (cancelledBy != null) ||
        cancelled != (cancelledAt != null) ||
        cancelled != (cancelReason != null)) {
      throw ArgumentError(
        'cancelled_by, cancelled_at and cancel_reason are set exactly when '
        'Cancelled',
      );
    }
  }

  @override
  final Id id;
  final Id contestId;

  /// The round whose score is affected.
  final Id creditedRoundId;

  /// The round where the awarding flight was flown.
  final Id sourceRoundId;

  final int sourceGroup;
  final ReFlightType type;

  /// The re-flight number for the source group, from 1.
  final int sequence;

  /// The re-flight this one follows, when a re-flight is itself re-flown.
  final Id? previousReflightId;

  final ReFlightStatus status;
  final String reason;
  final Id scheduledRoundId;

  /// The group it is flown in; a re-flight group is numbered after the
  /// round's regular groups.
  final int flownGroup;

  final bool deviationAcknowledged;

  /// `RandomDraw` only.
  final int? requestedGroupSize;
  final int? achievableMaxSize;
  final bool sizeExceptionConfirmed;
  final int? randomSeed;
  final String? algorithmVersion;

  final Id configRevisionId;
  final Id createdBy;
  final DateTime createdAt;
  final Id? groupFinalizedBy;
  final DateTime? groupFinalizedAt;
  final Id? finalizedBy;
  final DateTime? finalizedAt;
  final Id? cancelledBy;
  final DateTime? cancelledAt;
  final String? cancelReason;

  @override
  final int revision;

  bool get isCancelled => status == ReFlightStatus.cancelled;

  @override
  String get entityType => 'ReFlight';

  @override
  SyncScope get syncScope => SyncScope.contest;

  Map<String, Object?> toJson() => _$ReFlightToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    creditedRoundId,
    sourceRoundId,
    sourceGroup,
    type,
    sequence,
    previousReflightId,
    status,
    reason,
    scheduledRoundId,
    flownGroup,
    deviationAcknowledged,
    requestedGroupSize,
    achievableMaxSize,
    sizeExceptionConfirmed,
    randomSeed,
    algorithmVersion,
    configRevisionId,
    createdBy,
    createdAt,
    groupFinalizedBy,
    groupFinalizedAt,
    finalizedBy,
    finalizedAt,
    cancelledBy,
    cancelledAt,
    cancelReason,
    revision,
  ];
}
