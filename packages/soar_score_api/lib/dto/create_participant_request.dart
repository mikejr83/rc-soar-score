import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'create_participant_request.g.dart';

/// Body of `POST /api/v1/participants`.
///
/// The caller generates [id] (a UUIDv7), so repeating the request returns the
/// profile it created instead of creating another.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class CreateParticipantRequest {
  const CreateParticipantRequest({
    required this.id,
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

  factory CreateParticipantRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateParticipantRequestFromJson(json);

  final Id id;
  final String firstName;
  final String lastName;
  final String? club;
  final String? faiNumber;
  final String? nationalOrgId;
  final String? city;
  final String? state;
  final String? country;
  final String? email;

  Map<String, dynamic> toJson() => _$CreateParticipantRequestToJson(this);
}
