import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'create_role_request.g.dart';

/// Body of `POST /api/v1/roles`.
///
/// The caller generates [id] (a UUIDv7), so repeating the request returns the
/// role it created instead of creating another. A role the director adds is
/// always a non-flier.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class CreateRoleRequest {
  const CreateRoleRequest({required this.id, required this.displayName});

  factory CreateRoleRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateRoleRequestFromJson(json);

  final Id id;
  final String displayName;

  Map<String, dynamic> toJson() => _$CreateRoleRequestToJson(this);
}
