import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../id.dart';
import '../shared/shared.dart';
import 'contest_config.dart';

part 'contest_configuration_revision.g.dart';

/// One saved, append-only version of a contest's configuration.
///
/// It holds the full resolved settings, the discipline profile they are for
/// and the landing table in use. The current revision is the one with the
/// highest [revisionNumber]. See
/// `plan/data-model/entities/contest_configuration_revision.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class ContestConfigurationRevision extends Equatable implements SyncScoped {
  ContestConfigurationRevision({
    required this.id,
    required this.contestId,
    required this.revisionNumber,
    required this.disciplineProfileId,
    this.sourcePresetId,
    required this.config,
    this.landingTableId,
    required this.createdBy,
    this.notes,
    required DateTime createdAt,
  }) : createdAt = createdAt.toUtc() {
    if (revisionNumber < 1) {
      throw ArgumentError.value(
        revisionNumber,
        'revisionNumber',
        'starts at 1',
      );
    }
  }

  factory ContestConfigurationRevision.fromJson(Map<String, Object?> json) =>
      _$ContestConfigurationRevisionFromJson(json);

  final Id id;
  final Id contestId;

  /// Sequential number within the contest, starting at 1.
  final int revisionNumber;

  /// The same for every revision of a contest.
  final Id disciplineProfileId;

  /// The preset the first revision was copied from; not enforced afterwards.
  final Id? sourcePresetId;

  @JsonKey(fromJson: _configFromJson, toJson: _configToJson)
  final ContestConfig config;

  /// The landing table the contest uses for landing scores.
  final Id? landingTableId;

  /// The account that created the revision.
  final Id createdBy;

  final String? notes;
  final DateTime createdAt;

  @override
  SyncScope get syncScope => SyncScope.contest;

  Map<String, Object?> toJson() => _$ContestConfigurationRevisionToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    revisionNumber,
    disciplineProfileId,
    sourcePresetId,
    config,
    landingTableId,
    createdBy,
    notes,
    createdAt,
  ];
}

ContestConfig _configFromJson(Map<String, Object?> json) =>
    ContestConfig.fromJson(json);

Map<String, Object?> _configToJson(ContestConfig config) => config.toJson();
