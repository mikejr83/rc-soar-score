import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../id.dart';
import '../shared/shared.dart';
import 'contest_config.dart';

part 'contest_configuration_preset.g.dart';

/// A director's saved, named set of contest settings to start a contest from.
///
/// Director data. Creating a contest copies the preset, so later edits never
/// change that contest. See
/// `plan/data-model/entities/contest_configuration_preset.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class ContestConfigurationPreset extends Equatable implements Synchronizable {
  ContestConfigurationPreset({
    required this.id,
    required this.ownerAccountId,
    required this.disciplineProfileId,
    required String name,
    this.description,
    required this.config,
    this.landingTableId,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.revision = 0,
  }) : name = requireNotBlank(name, 'name'),
       createdAt = createdAt.toUtc(),
       updatedAt = updatedAt.toUtc() {
    requireNonNegative(revision, 'revision');
  }

  factory ContestConfigurationPreset.fromJson(Map<String, Object?> json) =>
      _$ContestConfigurationPresetFromJson(json);

  @override
  final Id id;

  /// The director who owns the preset.
  final Id ownerAccountId;

  final Id disciplineProfileId;

  /// Unique per owner, ignoring case.
  final String name;

  final String? description;

  @JsonKey(fromJson: _configFromJson, toJson: _configToJson)
  final ContestConfig config;

  final Id? landingTableId;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  final int revision;

  @override
  String get entityType => 'ContestConfigurationPreset';

  @override
  SyncScope get syncScope => SyncScope.director;

  Map<String, Object?> toJson() => _$ContestConfigurationPresetToJson(this);

  @override
  List<Object?> get props => [
    id,
    ownerAccountId,
    disciplineProfileId,
    name,
    description,
    config,
    landingTableId,
    createdAt,
    updatedAt,
    revision,
  ];
}

ContestConfig _configFromJson(Map<String, Object?> json) =>
    ContestConfig.fromJson(json);

Map<String, Object?> _configToJson(ContestConfig config) => config.toJson();
