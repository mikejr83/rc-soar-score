import 'package:json_annotation/json_annotation.dart';

part 'enter_score_request.g.dart';

/// Body of
/// `POST /api/v1/contests/{id}/assignments/{assignmentId}/scores`: the
/// components of a flight, entered by the director as the official score.
///
/// The caller generates [clientMutationId], so repeating the request returns
/// the entry it made the first time. [baseScoreRevision] is the score
/// revision the caller read from the slot's placeholder (0 when nothing has
/// been entered); a different stored revision is answered with 409. The
/// [components] are the discipline's entry fields, for example
/// `{"time_flown": 540, "launch_height": 180, "landing": "10"}` for F5J.
/// [reason] is required to correct a score that already has one.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class EnterScoreRequest {
  const EnterScoreRequest({
    required this.clientMutationId,
    required this.baseScoreRevision,
    required this.components,
    this.reason,
  });

  factory EnterScoreRequest.fromJson(Map<String, dynamic> json) =>
      _$EnterScoreRequestFromJson(json);

  final String clientMutationId;
  final int baseScoreRevision;
  final Map<String, Object?> components;
  final String? reason;

  Map<String, dynamic> toJson() => _$EnterScoreRequestToJson(this);
}
