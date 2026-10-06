import 'package:json_annotation/json_annotation.dart';

part 'update_team_request.g.dart';

/// Body of `PUT /api/v1/contests/{id}/teams/{teamId}`: the new [name].
///
/// [baseRevision] is the team revision the caller read; a different stored
/// revision is answered with 409.
@JsonSerializable(checked: true, fieldRename: FieldRename.snake)
class UpdateTeamRequest {
  const UpdateTeamRequest({required this.baseRevision, required this.name});

  factory UpdateTeamRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTeamRequestFromJson(json);

  final int baseRevision;
  final String name;

  Map<String, dynamic> toJson() => _$UpdateTeamRequestToJson(this);
}
