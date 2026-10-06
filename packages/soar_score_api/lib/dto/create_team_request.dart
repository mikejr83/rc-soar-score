import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'create_team_request.g.dart';

/// Body of `POST /api/v1/contests/{id}/teams`.
///
/// The caller generates [id] (a UUIDv7), so repeating the request returns the
/// team it created. The [name] is unique within the contest.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class CreateTeamRequest {
  const CreateTeamRequest({required this.id, required this.name});

  factory CreateTeamRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTeamRequestFromJson(json);

  final Id id;
  final String name;

  Map<String, dynamic> toJson() => _$CreateTeamRequestToJson(this);
}
