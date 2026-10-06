import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'update_participation_request.g.dart';

/// Body of `PUT /api/v1/contests/{id}/participations/{participationId}`.
///
/// A null [roleId] keeps the role. [classification] and [retiredAtRound]
/// replace the stored values, so null clears them (reversing a retirement).
/// [baseRevision] is the participation revision the caller read; a different
/// stored revision is answered with 409.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class UpdateParticipationRequest {
  const UpdateParticipationRequest({
    required this.baseRevision,
    this.roleId,
    this.classification,
    this.retiredAtRound,
  });

  factory UpdateParticipationRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateParticipationRequestFromJson(json);

  final int baseRevision;
  final Id? roleId;
  final String? classification;
  final int? retiredAtRound;

  Map<String, dynamic> toJson() => _$UpdateParticipationRequestToJson(this);
}
