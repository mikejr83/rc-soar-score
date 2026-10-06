import 'package:json_annotation/json_annotation.dart';
import 'package:soar_score_core/soar_score_core.dart';

part 'save_configuration_request.g.dart';

/// Body of `POST /api/v1/contests/{id}/configuration`: the settings to store
/// as the contest's next configuration revision.
///
/// [baseRevisionNumber] is the latest revision number the caller read, or 0
/// when the contest has no configuration yet; a different latest revision is
/// answered with 409. [disciplineProfileId] is chosen with the first revision
/// and must be the same afterwards. [landingTableId] defaults to the
/// profile's own table for a discipline that scores landings.
@JsonSerializable(
  checked: true,
  fieldRename: FieldRename.snake,
  includeIfNull: true,
)
@IdConverter()
class SaveConfigurationRequest {
  const SaveConfigurationRequest({
    required this.baseRevisionNumber,
    required this.disciplineProfileId,
    required this.config,
    this.landingTableId,
    this.notes,
  });

  factory SaveConfigurationRequest.fromJson(Map<String, dynamic> json) =>
      _$SaveConfigurationRequestFromJson(json);

  final int baseRevisionNumber;
  final Id disciplineProfileId;

  /// `{"core": {...}, "discipline": {...}}`.
  @JsonKey(fromJson: _configFromJson, toJson: _configToJson)
  final ContestConfig config;
  final Id? landingTableId;
  final String? notes;

  Map<String, dynamic> toJson() => _$SaveConfigurationRequestToJson(this);
}

ContestConfig _configFromJson(Map<String, dynamic> json) =>
    ContestConfig.fromJson(json);

Map<String, dynamic> _configToJson(ContestConfig config) => config.toJson();
