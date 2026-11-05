import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

import 'participant_overview_dto.dart';

part 'participant_submit_dto.g.dart';

/// Error codes of the participant endpoints. Wire values of
/// `ApiErrorDto.code` and `ParticipantErrorDto.code`.
abstract final class ParticipantErrorCodes {
  /// The invitation is unknown, expired, replaced or revoked. The answer is
  /// identical for all of them and says nothing about the contest or pilot.
  static const invalidInvitation = 'invalid_invitation';

  /// The session's invitation no longer works; discard cached data.
  static const sessionInvalid = 'session_invalid';

  /// The flight already has an accepted score.
  static const scoreAlreadySubmitted = 'score_already_submitted';

  /// A field is missing, of the wrong type, out of range, or not allowed.
  static const validationFailed = 'validation_failed';

  /// Scoring is closed, locked or the contest is read-only.
  static const scoringClosed = 'scoring_closed';

  /// The matrix changed since the client read it.
  static const staleMatrix = 'stale_matrix';

  /// An earlier round must be scored first.
  static const outOfOrder = 'out_of_order';

  /// The same request id was reused with different data.
  static const mutationConflict = 'mutation_conflict';
}

/// Body of `POST /api/v1/self-scoring/rounds/{round}/scores`.
///
/// The server derives the pilot and assignment from the session; only the
/// ids needed to detect staleness are sent. Repeating the request with the
/// same [clientMutationId] returns the first acceptance.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class SubmitParticipantScoreRequest {
  const SubmitParticipantScoreRequest({
    required this.clientMutationId,
    required this.matrixRevision,
    required this.components,
  });

  factory SubmitParticipantScoreRequest.fromJson(Map<String, dynamic> json) =>
      _$SubmitParticipantScoreRequestFromJson(json);

  final String clientMutationId;
  final int matrixRevision;

  /// The entry fields, for example
  /// `{"time_flown": 540, "launch_height": 45, "landing": "good_50"}`.
  final Map<String, Object?> components;

  Map<String, dynamic> toJson() => _$SubmitParticipantScoreRequestToJson(this);
}

/// An accepted participant score as the participant sees it.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class ParticipantScoreDto {
  const ParticipantScoreDto({
    required this.assignmentId,
    required this.round,
    required this.state,
    required this.revision,
    required this.components,
    required this.enteredBy,
    required this.enteredAt,
    this.flightScore,
    this.validationMessages = const [],
  });

  factory ParticipantScoreDto.fromJson(Map<String, dynamic> json) =>
      _$ParticipantScoreDtoFromJson(json);

  final Id assignmentId;
  final int round;
  final ParticipantScoreState state;
  final int revision;

  /// The stored raw components, as submitted.
  final Map<String, Object?> components;
  final String enteredBy;
  final DateTime enteredAt;

  /// The calculated flight score. A calculated value, not an entered one.
  final num? flightScore;
  final List<String> validationMessages;

  Map<String, dynamic> toJson() => _$ParticipantScoreDtoToJson(this);
}

/// The answer to an accepted submission.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class SubmitParticipantScoreResponse {
  const SubmitParticipantScoreResponse({
    required this.score,
    required this.nextOperation,
    this.nextRound,
  });

  factory SubmitParticipantScoreResponse.fromJson(Map<String, dynamic> json) =>
      _$SubmitParticipantScoreResponseFromJson(json);

  final ParticipantScoreDto score;

  /// What may happen next: `view_results` in the first release, later
  /// `request_review`.
  final String nextOperation;

  /// The next round to score, or null after the last one.
  final int? nextRound;

  Map<String, dynamic> toJson() => _$SubmitParticipantScoreResponseToJson(this);
}

/// One field-level problem in a rejected submission.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class FieldErrorDto {
  const FieldErrorDto({required this.field, required this.code});

  factory FieldErrorDto.fromJson(Map<String, dynamic> json) =>
      _$FieldErrorDtoFromJson(json);

  final String field;

  /// `required`, `wrong_type`, `out_of_range`, `not_allowed`.
  final String code;

  Map<String, dynamic> toJson() => _$FieldErrorDtoToJson(this);
}

/// The `error` object of a rejected participant call. A superset of
/// [ApiErrorDto]: the same `code`, `message` and `request_id`, plus the
/// detail some rejections carry. An invalid or replaced credential carries
/// none of it.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class ParticipantErrorDto {
  const ParticipantErrorDto({
    required this.code,
    required this.message,
    this.requestId,
    this.acceptedScore,
    this.nextOperation,
    this.fieldErrors = const [],
  });

  factory ParticipantErrorDto.fromJson(Map<String, dynamic> json) =>
      _$ParticipantErrorDtoFromJson(json);

  final String code;
  final String message;
  final String? requestId;

  /// With `score_already_submitted`: the score that was accepted first.
  final ParticipantScoreDto? acceptedScore;
  final String? nextOperation;
  final List<FieldErrorDto> fieldErrors;

  Map<String, dynamic> toJson() => _$ParticipantErrorDtoToJson(this);
}
