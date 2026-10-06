import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'add_team_member_request.g.dart';

/// Body of `POST /api/v1/contests/{id}/team-memberships`.
///
/// The caller generates [id] (a UUIDv7), so repeating the request returns the
/// membership it created.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class AddTeamMemberRequest {
  const AddTeamMemberRequest({
    required this.id,
    required this.teamId,
    required this.contestParticipationId,
  });

  factory AddTeamMemberRequest.fromJson(Map<String, dynamic> json) =>
      _$AddTeamMemberRequestFromJson(json);

  final Id id;
  final Id teamId;
  final Id contestParticipationId;

  Map<String, dynamic> toJson() => _$AddTeamMemberRequestToJson(this);
}
