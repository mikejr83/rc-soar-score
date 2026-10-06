import 'package:json_annotation/json_annotation.dart';

part 'update_participant_request.g.dart';

/// Body of `PUT /api/v1/participants/{id}`: the full details of the profile.
/// An omitted or null optional field clears it.
///
/// [baseRevision] is the profile revision the caller read; a different stored
/// revision is answered with 409.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class UpdateParticipantRequest {
  const UpdateParticipantRequest({
    required this.baseRevision,
    required this.firstName,
    required this.lastName,
    this.club,
    this.faiNumber,
    this.nationalOrgId,
    this.city,
    this.state,
    this.country,
    this.email,
  });

  factory UpdateParticipantRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateParticipantRequestFromJson(json);

  final int baseRevision;
  final String firstName;
  final String lastName;
  final String? club;
  final String? faiNumber;
  final String? nationalOrgId;
  final String? city;
  final String? state;
  final String? country;
  final String? email;

  Map<String, dynamic> toJson() => _$UpdateParticipantRequestToJson(this);
}
