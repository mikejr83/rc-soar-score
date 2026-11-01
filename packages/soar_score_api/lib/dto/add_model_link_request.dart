import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'add_model_link_request.g.dart';

/// Body of `POST /api/v1/contests/{id}/participations/{participationId}/model-links`.
///
/// The caller generates [id] (a UUIDv7), so repeating the request returns the
/// link it created. With [modelCatalogId] (a model of the pilot's profile)
/// and no [modelName] the link starts as a copy of that model, and a
/// [manufacturer] or [modelId] overrides the copy. With a [modelName] the link
/// holds exactly the fields given. Without [modelCatalogId], [modelName] is
/// required.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class AddModelLinkRequest {
  const AddModelLinkRequest({
    required this.id,
    this.modelCatalogId,
    this.modelName,
    this.manufacturer,
    this.modelId,
    this.contestSpecificIdentifier,
  });

  factory AddModelLinkRequest.fromJson(Map<String, dynamic> json) =>
      _$AddModelLinkRequestFromJson(json);

  final Id id;
  final Id? modelCatalogId;
  final String? modelName;
  final String? manufacturer;
  final String? modelId;
  final String? contestSpecificIdentifier;

  Map<String, dynamic> toJson() => _$AddModelLinkRequestToJson(this);
}
