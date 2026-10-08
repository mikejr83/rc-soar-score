import 'package:json_annotation/json_annotation.dart';

part 'set_visibility_request.g.dart';

/// Body of `PATCH /api/v1/contests/{id}/publication/visibility`.
///
/// [visibility] is `Unlisted` or `Public`; any other value is answered with
/// 400.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class SetVisibilityRequest {
  const SetVisibilityRequest({required this.visibility});

  factory SetVisibilityRequest.fromJson(Map<String, dynamic> json) =>
      _$SetVisibilityRequestFromJson(json);

  final String visibility;

  Map<String, dynamic> toJson() => _$SetVisibilityRequestToJson(this);
}
