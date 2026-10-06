import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'add_participation_request.g.dart';

/// Body of `POST /api/v1/contests/{id}/participations`.
///
/// The caller generates [id] (a UUIDv7), so repeating the request returns the
/// participation it created. A null [roleId] is the system Pilot role.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class AddParticipationRequest {
  const AddParticipationRequest({
    required this.id,
    required this.participantProfileId,
    this.roleId,
    this.classification,
  });

  factory AddParticipationRequest.fromJson(Map<String, dynamic> json) =>
      _$AddParticipationRequestFromJson(json);

  final Id id;
  final Id participantProfileId;
  final Id? roleId;
  final String? classification;

  Map<String, dynamic> toJson() => _$AddParticipationRequestToJson(this);
}
