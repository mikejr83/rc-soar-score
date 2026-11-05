import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'participant_invitation_dto.dart';

part 'participant_overview_dto.g.dart';

/// Where a round stands for one pilot. Wire values are the snake_case names
/// of the states in `participant-score-entry.md`.
@JsonEnum(fieldRename: FieldRename.snake)
enum ParticipantScoreState {
  notEntered,
  draft,
  submitted,
  reviewRequested,
  underReview,
  official,
  locked,
  zero,
  retired,
}

/// One round of the pilot's draw and the state of its score.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class ParticipantRoundDto {
  const ParticipantRoundDto({
    required this.round,
    required this.group,
    required this.lane,
    required this.assignmentId,
    required this.state,
    required this.isNextToScore,
    this.enteredBy,
    this.enteredAt,
    this.scoreRevision = 0,
  });

  factory ParticipantRoundDto.fromJson(Map<String, dynamic> json) =>
      _$ParticipantRoundDtoFromJson(json);

  final int round;
  final String group;
  final int lane;

  /// The server derives the assignment from the session; the app sends
  /// this id back only to name the round it is entering.
  final Id assignmentId;
  final ParticipantScoreState state;

  /// True for the first eligible round without a submitted score. The
  /// server refuses an out-of-order submission.
  final bool isNextToScore;

  /// Who entered the score: the pilot's own name or another name.
  final String? enteredBy;
  final DateTime? enteredAt;
  final int scoreRevision;

  Map<String, dynamic> toJson() => _$ParticipantRoundDtoToJson(this);
}

/// The answer to `GET /api/v1/self-scoring/overview`: everything the pilot
/// overview shows, for the session's own pilot only.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class ParticipantOverviewDto {
  const ParticipantOverviewDto({
    required this.contest,
    required this.participant,
    required this.matrixRevision,
    required this.locked,
    required this.rounds,
  });

  factory ParticipantOverviewDto.fromJson(Map<String, dynamic> json) =>
      _$ParticipantOverviewDtoFromJson(json);

  final ParticipantContestDto contest;
  final ParticipantLinkDto participant;
  final int matrixRevision;

  /// True when the administration lock or lifecycle stops all submissions.
  final bool locked;
  final List<ParticipantRoundDto> rounds;

  Map<String, dynamic> toJson() => _$ParticipantOverviewDtoToJson(this);
}
