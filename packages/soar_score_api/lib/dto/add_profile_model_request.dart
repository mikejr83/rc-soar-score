import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'add_profile_model_request.g.dart';

/// Body of `POST /api/v1/participants/{id}/models`: a model of the profile.
///
/// The caller generates [id] (a UUIDv7), so repeating the request returns the
/// model it created. [modelId] is the identifier the pilot applied to it.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class AddProfileModelRequest {
  const AddProfileModelRequest({
    required this.id,
    required this.name,
    this.manufacturer,
    this.modelId,
  });

  factory AddProfileModelRequest.fromJson(Map<String, dynamic> json) =>
      _$AddProfileModelRequestFromJson(json);

  final Id id;
  final String name;
  final String? manufacturer;
  final String? modelId;

  Map<String, dynamic> toJson() => _$AddProfileModelRequestToJson(this);
}
