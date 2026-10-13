import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'activate_installation_request.g.dart';

/// Body of `POST /api/v1/contests/{id}/activations`.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class ActivateInstallationRequest {
  const ActivateInstallationRequest({
    required this.installationId,
    required this.kind,
  });

  factory ActivateInstallationRequest.fromJson(Map<String, dynamic> json) =>
      _$ActivateInstallationRequestFromJson(json);

  final Id installationId;
  final ActivationKind kind;

  Map<String, dynamic> toJson() => _$ActivateInstallationRequestToJson(this);
}
