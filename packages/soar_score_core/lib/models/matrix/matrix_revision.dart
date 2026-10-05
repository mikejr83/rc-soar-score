import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/draw_mode.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'matrix_revision.g.dart';

/// One draw of the flight matrix, kept so the draw can be reproduced.
///
/// A draft has no finalizer; finalizing is write-once. See
/// `plan/data-model/entities/matrix_revision.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class MatrixRevision extends Equatable implements AppendOnly {
  MatrixRevision({
    required this.id,
    required this.contestId,
    required this.revisionNumber,
    this.previousRevisionId,
    required this.firstRound,
    required this.lastRound,
    required this.drawMode,
    required this.randomSeed,
    required String algorithmVersion,
    required Map<String, Object?> drawConfig,
    required Map<String, Object?> seedingSnapshot,
    Map<String, Object?>? fairnessSummary,
    this.reason,
    required this.createdBy,
    required DateTime createdAt,
    this.finalizedBy,
    DateTime? finalizedAt,
  }) : algorithmVersion = requireNotBlank(algorithmVersion, 'algorithmVersion'),
       drawConfig = Map.unmodifiable(drawConfig),
       seedingSnapshot = Map.unmodifiable(seedingSnapshot),
       fairnessSummary = fairnessSummary == null
           ? null
           : Map.unmodifiable(fairnessSummary),
       createdAt = createdAt.toUtc(),
       finalizedAt = finalizedAt?.toUtc() {
    requirePositive(revisionNumber, 'revisionNumber');
    requirePositive(firstRound, 'firstRound');
    if (lastRound < firstRound) {
      throw ArgumentError.value(
        lastRound,
        'lastRound',
        'must not precede firstRound',
      );
    }
    requireSeed(randomSeed, 'randomSeed');
    if ((previousRevisionId == null) != (revisionNumber == 1)) {
      throw ArgumentError(
        'only the first revision has no previous_revision_id',
      );
    }
    if (previousRevisionId == null && firstRound != 1) {
      throw ArgumentError('the first revision starts at round 1');
    }
    if ((finalizedBy == null) != (finalizedAt == null)) {
      throw ArgumentError('finalized_by and finalized_at are set together');
    }
  }

  factory MatrixRevision.fromJson(Map<String, Object?> json) =>
      _$MatrixRevisionFromJson(json);

  @override
  final Id id;
  final Id contestId;

  /// Sequential number of this draw within the contest, from 1.
  final int revisionNumber;

  /// The latest finalized revision when this one was created.
  final Id? previousRevisionId;

  final int firstRound;
  final int lastRound;
  final DrawMode drawMode;

  /// Unsigned 32-bit seed for the draw's random generator.
  final int randomSeed;

  final String algorithmVersion;

  /// The settings the draw used.
  final Map<String, Object?> drawConfig;

  /// The draw's inputs at the time of the draw.
  final Map<String, Object?> seedingSnapshot;

  final Map<String, Object?>? fairnessSummary;
  final String? reason;
  final Id createdBy;
  final DateTime createdAt;

  /// Write-once; null while the revision is a draft.
  final Id? finalizedBy;
  final DateTime? finalizedAt;

  bool get isFinalized => finalizedAt != null;

  @override
  String get entityType => 'MatrixRevision';

  @override
  SyncScope get syncScope => SyncScope.contest;

  Map<String, Object?> toJson() => _$MatrixRevisionToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    revisionNumber,
    previousRevisionId,
    firstRound,
    lastRound,
    drawMode,
    randomSeed,
    algorithmVersion,
    drawConfig,
    seedingSnapshot,
    fairnessSummary,
    reason,
    createdBy,
    createdAt,
    finalizedBy,
    finalizedAt,
  ];
}
