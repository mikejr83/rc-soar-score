import 'package:json_annotation/json_annotation.dart';

part 'update_profile_model_request.g.dart';

/// Body of `PUT /api/v1/participants/{id}/models/{modelId}`: the full details
/// of the model. An omitted or null optional field clears it.
///
/// [baseRevision] is the model revision the caller read; a different stored
/// revision is answered with 409.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class UpdateProfileModelRequest {
  const UpdateProfileModelRequest({
    required this.baseRevision,
    required this.name,
    this.manufacturer,
    this.modelId,
  });

  factory UpdateProfileModelRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateProfileModelRequestFromJson(json);

  final int baseRevision;
  final String name;
  final String? manufacturer;
  final String? modelId;

  Map<String, dynamic> toJson() => _$UpdateProfileModelRequestToJson(this);
}
