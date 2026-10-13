import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'register_installation_request.g.dart';

/// Body of `POST /api/v1/installations`.
///
/// The installation generates its own [id]; registering it again returns the
/// stored row.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class RegisterInstallationRequest {
  const RegisterInstallationRequest({
    required this.id,
    required this.label,
    required this.platform,
  });

  factory RegisterInstallationRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterInstallationRequestFromJson(json);

  final Id id;
  final String label;
  final Platform platform;

  Map<String, dynamic> toJson() => _$RegisterInstallationRequestToJson(this);
}
