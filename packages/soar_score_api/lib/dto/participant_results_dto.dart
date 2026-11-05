import 'package:json_annotation/json_annotation.dart';

import 'participant_overview_dto.dart';

part 'participant_results_dto.g.dart';

/// One pilot's flight in the group a participant flew in.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class ParticipantGroupRowDto {
  const ParticipantGroupRowDto({
    required this.pilotName,
    required this.pilotNumber,
    required this.state,
    required this.isYou,
    required this.isEstimate,
    this.timeFlownSeconds,
    this.launchHeight,
    this.landing,
    this.flightScore,
    this.zeroReason,
    this.reviewPending = false,
  });

  factory ParticipantGroupRowDto.fromJson(Map<String, dynamic> json) =>
      _$ParticipantGroupRowDtoFromJson(json);

  final String pilotName;
  final int pilotNumber;
  final ParticipantScoreState state;
  final bool isYou;

  /// True when the score is a missing-score estimate, not an entered one.
  final bool isEstimate;
  final int? timeFlownSeconds;
  final num? launchHeight;
  final String? landing;

  /// The calculated normalised flight score.
  final num? flightScore;
  final String? zeroReason;
  final bool reviewPending;

  Map<String, dynamic> toJson() => _$ParticipantGroupRowDtoToJson(this);
}

/// The answer to
/// `GET /api/v1/self-scoring/rounds/{round}/group-results`.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class ParticipantGroupResultsDto {
  const ParticipantGroupResultsDto({
    required this.round,
    required this.group,
    required this.latestRound,
    required this.preliminary,
    required this.rows,
  });

  factory ParticipantGroupResultsDto.fromJson(Map<String, dynamic> json) =>
      _$ParticipantGroupResultsDtoFromJson(json);

  final int round;
  final String group;

  /// The round the overall results link points to.
  final int latestRound;

  /// True while the group or ranking is incomplete.
  final bool preliminary;
  final List<ParticipantGroupRowDto> rows;

  Map<String, dynamic> toJson() => _$ParticipantGroupResultsDtoToJson(this);
}

/// One line of the overall individual standings.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class ParticipantStandingDto {
  const ParticipantStandingDto({
    required this.place,
    required this.pilotName,
    required this.pilotNumber,
    required this.score,
    required this.isYou,
    this.tied = false,
  });

  factory ParticipantStandingDto.fromJson(Map<String, dynamic> json) =>
      _$ParticipantStandingDtoFromJson(json);

  final int place;
  final String pilotName;
  final int pilotNumber;
  final num score;
  final bool isYou;
  final bool tied;

  Map<String, dynamic> toJson() => _$ParticipantStandingDtoToJson(this);
}

/// The answer to `GET /api/v1/self-scoring/results?round={n}`: overall
/// individual standings as of a round. Team standings join later.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class ParticipantOverallResultsDto {
  const ParticipantOverallResultsDto({
    required this.asOfRound,
    required this.latestRound,
    required this.preliminary,
    required this.standings,
    this.heldAtRound,
    this.yourPlace,
    this.yourScore,
  });

  factory ParticipantOverallResultsDto.fromJson(Map<String, dynamic> json) =>
      _$ParticipantOverallResultsDtoFromJson(json);

  /// The round the standings are as of.
  final int asOfRound;
  final int latestRound;

  /// The round standings are held at while the director hides overall
  /// results; null when nothing is hidden. Round scores and group positions
  /// stay current.
  final int? heldAtRound;
  final bool preliminary;
  final int? yourPlace;
  final num? yourScore;
  final List<ParticipantStandingDto> standings;

  Map<String, dynamic> toJson() => _$ParticipantOverallResultsDtoToJson(this);
}
