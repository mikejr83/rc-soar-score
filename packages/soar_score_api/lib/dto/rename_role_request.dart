import 'package:json_annotation/json_annotation.dart';

part 'rename_role_request.g.dart';

/// Body of `PUT /api/v1/roles/{id}`: the role's new name.
///
/// [baseRevision] is the role revision the caller read; a different stored
/// revision is answered with 409.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
class RenameRoleRequest {
  const RenameRoleRequest({
    required this.baseRevision,
    required this.displayName,
  });

  factory RenameRoleRequest.fromJson(Map<String, dynamic> json) =>
      _$RenameRoleRequestFromJson(json);

  final int baseRevision;
  final String displayName;

  Map<String, dynamic> toJson() => _$RenameRoleRequestToJson(this);
}
