import 'package:json_annotation/json_annotation.dart';

part 'promote_score_request.g.dart';

/// Body of
/// `POST /api/v1/contests/{id}/assignments/{assignmentId}/scores/official`:
/// the director accepts a stored participant submission as the official
/// score ("mark official").
///
/// It carries no score components: the server adopts the submission it
/// stored. [sourceAttemptId] is the submission the director saw and
/// [expectedScoreRevision] the slot's score revision at that time; anything
/// else is answered with 409 (`stale_revision`) and nothing is stored. A
/// repeat of an adoption that already happened is answered 200 with
/// `replayed: true`.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class PromoteScoreRequest {
  const PromoteScoreRequest({
    required this.sourceAttemptId,
    required this.expectedScoreRevision,
  });

  factory PromoteScoreRequest.fromJson(Map<String, dynamic> json) =>
      _$PromoteScoreRequestFromJson(json);

  final String sourceAttemptId;
  @JsonKey(fromJson: _wholeNumber)
  final int expectedScoreRevision;

  Map<String, dynamic> toJson() => _$PromoteScoreRequestToJson(this);
}

/// A JSON whole number as an int; a fraction such as 1.9, which the generated
/// decoder would truncate, or any other type is refused.
int _wholeNumber(Object? value) {
  if (value is int) return value;
  if (value is double && value == value.truncateToDouble() && value.isFinite) {
    return value.toInt();
  }
  throw ArgumentError.value(
    value,
    'expected_score_revision',
    'not a whole number',
  );
}
