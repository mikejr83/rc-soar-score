import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/flight_outcome.dart';
import '../id.dart';
import '../shared/shared.dart';
import 'provenance.dart';

part 'flight_result.g.dart';

/// The calculated result of one flight, stored so it can be shown without
/// recomputing.
///
/// Derived data: written only by the calculator and replaced whenever it is
/// recomputed. Scores are plain `double` values (see the ticket's score
/// decision). See `plan/data-model/entities/flight_result.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class FlightResult extends Equatable implements SyncScoped {
  FlightResult({
    required this.id,
    required this.contestId,
    required this.scorePlaceholderId,
    required this.officialScoreId,
    required this.contestParticipationId,
    required this.creditedRoundId,
    required this.outcome,
    required this.rawPoints,
    this.landingPoints,
    this.flightPenaltyPoints,
    this.cumulativePenalty,
    required this.groupScore,
    this.isSelected = true,
    required this.isPreliminary,
    required this.configRevisionId,
    required this.matrixRevisionId,
    required String calculationVersion,
    required DateTime computedAt,
  }) : calculationVersion = requireNotBlank(
         calculationVersion,
         'calculationVersion',
       ),
       computedAt = computedAt.toUtc() {
    _requireNonNegativeScore(rawPoints, 'rawPoints');
    if (landingPoints != null) {
      _requireNonNegativeScore(landingPoints!, 'landingPoints');
    }
    if (flightPenaltyPoints != null) {
      _requireNonNegativeScore(flightPenaltyPoints!, 'flightPenaltyPoints');
    }
    if (cumulativePenalty != null) {
      requireNonNegative(cumulativePenalty!, 'cumulativePenalty');
    }
    _requireNonNegativeScore(groupScore, 'groupScore');
  }

  factory FlightResult.fromJson(Map<String, Object?> json) =>
      _$FlightResultFromJson(json);

  static void _requireNonNegativeScore(double value, String name) {
    if (value.isNaN || value < 0) {
      throw ArgumentError.value(value, name, 'must not be negative');
    }
  }

  final Id id;
  final Id contestId;

  /// One current result per flight.
  final Id scorePlaceholderId;

  /// The official score version this was computed from.
  final Id officialScoreId;

  final Id contestParticipationId;
  final Id creditedRoundId;
  final FlightOutcome outcome;

  /// Flight points plus any landing bonus minus penalties, never below zero.
  final double rawPoints;

  /// Null when the discipline has no landing score or the bonus was forfeited.
  final double? landingPoints;

  /// Penalty points deducted from the raw points; null when none.
  final double? flightPenaltyPoints;

  /// Copy of the official score's cumulative penalty; zero when one was
  /// applied and removed.
  final int? cumulativePenalty;

  /// The normalized round result, rounded or truncated once as configured.
  final double groupScore;

  /// Whether this flight supplies the pilot's round result for its round.
  final bool isSelected;

  /// True while the group or round is incomplete.
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

  Map<String, Object?> toJson() => _$FlightResultToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    scorePlaceholderId,
    officialScoreId,
    contestParticipationId,
    creditedRoundId,
    outcome,
    rawPoints,
    landingPoints,
    flightPenaltyPoints,
    cumulativePenalty,
    groupScore,
    isSelected,
    isPreliminary,
    configRevisionId,
    matrixRevisionId,
    calculationVersion,
    computedAt,
  ];
}
