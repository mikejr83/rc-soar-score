import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/round_status.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'round.g.dart';

/// A numbered round of the matrix, created by one matrix revision.
///
/// Group sizes are derived, never stored. See
/// `plan/data-model/entities/round.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class Round extends Equatable implements Synchronizable {
  Round({
    required this.id,
    required this.contestId,
    required this.matrixRevisionId,
    required this.ordinal,
    required this.groupCount,
    this.status = RoundStatus.open,
    this.supersededByRoundId,
    this.revision = 0,
  }) {
    requirePositive(ordinal, 'ordinal');
    requirePositive(groupCount, 'groupCount');
    if (supersededByRoundId == id) {
      throw ArgumentError('a round cannot supersede itself');
    }
    requireNonNegative(revision, 'revision');
  }

  factory Round.fromJson(Map<String, Object?> json) => _$RoundFromJson(json);

  @override
  final Id id;
  final Id contestId;
  final Id matrixRevisionId;

  /// Round number within the contest, from 1.
  final int ordinal;

  /// Regular groups made by the draw; re-flight groups are extra.
  final int groupCount;

  final RoundStatus status;

  /// The round of a later revision that replaced this one; write-once.
  final Id? supersededByRoundId;

  @override
  final int revision;

  bool get isSuperseded => supersededByRoundId != null;

  /// Whether this is the round for its ordinal: neither superseded nor
  /// cancelled.
  bool get isCurrent => !isSuperseded && status != RoundStatus.cancelled;

  @override
  String get entityType => 'Round';

  @override
  SyncScope get syncScope => SyncScope.contest;

  Map<String, Object?> toJson() => _$RoundToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    matrixRevisionId,
    ordinal,
    groupCount,
    status,
    supersededByRoundId,
    revision,
  ];
}
