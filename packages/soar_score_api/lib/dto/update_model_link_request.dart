import 'package:json_annotation/json_annotation.dart';

part 'update_model_link_request.g.dart';

/// Body of `PUT /api/v1/contests/{id}/model-links/{linkId}`: the full details
/// of the link. An omitted or null optional field clears it.
///
/// [baseRevision] is the link revision the caller read; a different stored
/// revision is answered with 409.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class UpdateModelLinkRequest {
  const UpdateModelLinkRequest({
    required this.baseRevision,
    required this.modelName,
    this.manufacturer,
    this.modelId,
    this.contestSpecificIdentifier,
  });

  factory UpdateModelLinkRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateModelLinkRequestFromJson(json);

  final int baseRevision;
  final String modelName;
  final String? manufacturer;
  final String? modelId;
  final String? contestSpecificIdentifier;

  Map<String, dynamic> toJson() => _$UpdateModelLinkRequestToJson(this);
}
