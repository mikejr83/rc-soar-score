import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../id.dart';
import '../shared/shared.dart';
import 'provenance.dart';

part 'team_standing.g.dart';

/// A team's standing as of a round: the sum of its best pilot scores.
///
/// Derived data; the team score is never entered. See
/// `plan/data-model/entities/team_standing.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class TeamStanding extends Equatable implements SyncScoped {
  TeamStanding({
    required this.id,
    required this.contestId,
    required this.teamId,
    required this.asOfRound,
    required this.place,
    this.isTied = false,
    required this.teamScore,
    List<Id> countedParticipations = const [],
    required this.isPreliminary,
    required this.configRevisionId,
    required this.matrixRevisionId,
    required String calculationVersion,
    required DateTime computedAt,
  }) : countedParticipations = List.unmodifiable(countedParticipations),
       calculationVersion = requireNotBlank(
         calculationVersion,
         'calculationVersion',
       ),
       computedAt = computedAt.toUtc() {
    requirePositive(asOfRound, 'asOfRound');
    requirePositive(place, 'place');
    if (countedParticipations.toSet().length != countedParticipations.length) {
      throw ArgumentError('a pilot is counted once in a team score');
    }
  }

  factory TeamStanding.fromJson(Map<String, Object?> json) =>
      _$TeamStandingFromJson(json);

  final Id id;
  final Id contestId;
  final Id teamId;

  /// The round ordinal the standing is as of.
  final int asOfRound;

  /// Team place; tied teams share a place.
  final int place;

  /// True when the tie is unresolved after the team tie-breakers.
  final bool isTied;

  /// Sum of the counted pilots' overall scores.
  final double teamScore;

  /// The pilots whose scores count, highest score first.
  final List<Id> countedParticipations;

  /// True while any counted pilot's standing is preliminary.
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

  Map<String, Object?> toJson() => _$TeamStandingToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    teamId,
    asOfRound,
    place,
    isTied,
    teamScore,
    countedParticipations,
    isPreliminary,
    configRevisionId,
    matrixRevisionId,
    calculationVersion,
    computedAt,
  ];
}
