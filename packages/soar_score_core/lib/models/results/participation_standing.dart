import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../id.dart';
import '../shared/shared.dart';
import 'provenance.dart';

part 'participation_standing.g.dart';

/// A pilot's overall standing as of a round, stored so overall results can be
/// shown without recomputing.
///
/// Derived data, one row per pilot for each completed round. See
/// `plan/data-model/entities/participation_standing.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class ParticipationStanding extends Equatable implements SyncScoped {
  ParticipationStanding({
    required this.id,
    required this.contestId,
    required this.contestParticipationId,
    required this.asOfRound,
    required this.place,
    this.isTied = false,
    required this.rawTotal,
    List<int> droppedRounds = const [],
    this.penaltyTotal = 0,
    required this.overallScore,
    required this.isPreliminary,
    required this.configRevisionId,
    required this.matrixRevisionId,
    required String calculationVersion,
    required DateTime computedAt,
  }) : droppedRounds = List.unmodifiable(droppedRounds),
       calculationVersion = requireNotBlank(
         calculationVersion,
         'calculationVersion',
       ),
       computedAt = computedAt.toUtc() {
    requirePositive(asOfRound, 'asOfRound');
    requirePositive(place, 'place');
    if (rawTotal.isNaN || rawTotal < 0) {
      throw ArgumentError.value(rawTotal, 'rawTotal', 'must not be negative');
    }
    if (penaltyTotal.isNaN || penaltyTotal < 0) {
      throw ArgumentError.value(
        penaltyTotal,
        'penaltyTotal',
        'must not be negative',
      );
    }
    for (final round in droppedRounds) {
      requirePositive(round, 'droppedRounds');
    }
  }

  factory ParticipationStanding.fromJson(Map<String, Object?> json) =>
      _$ParticipationStandingFromJson(json);

  final Id id;
  final Id contestId;
  final Id contestParticipationId;

  /// The round ordinal the standing is as of; not a foreign key.
  final int asOfRound;

  /// Overall place; tied pilots share a place.
  final int place;

  /// True when the tie is unresolved after every tie-breaker.
  final bool isTied;

  /// Sum of selected round scores before drops and penalties.
  final double rawTotal;

  /// Round ordinals dropped as of this round.
  final List<int> droppedRounds;

  /// Sum of the cumulative penalties on the pilot's official flights.
  final double penaltyTotal;

  /// Kept round scores minus the penalty total.
  final double overallScore;

  final bool isPreliminary;
  final Id configRevisionId;
  final Id matrixRevisionId;
  final String calculationVersion;
  final DateTime computedAt;

  /// Whether the version stamps differ from the current ones.
  bool isStale({
    required Id currentConfigRevisionId,
    required Id currentMatrixRevisionId,
    required String currentCalculationVersion,
  }) => isStaleResult(
    configRevisionId: configRevisionId,
    matrixRevisionId: matrixRevisionId,
    calculationVersion: calculationVersion,
    currentConfigRevisionId: currentConfigRevisionId,
    currentMatrixRevisionId: currentMatrixRevisionId,
    currentCalculationVersion: currentCalculationVersion,
  );

  @override
  SyncScope get syncScope => SyncScope.derived;

  Map<String, Object?> toJson() => _$ParticipationStandingToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    contestParticipationId,
    asOfRound,
    place,
    isTied,
    rawTotal,
    droppedRounds,
    penaltyTotal,
    overallScore,
    isPreliminary,
    configRevisionId,
    matrixRevisionId,
    calculationVersion,
    computedAt,
  ];
}
