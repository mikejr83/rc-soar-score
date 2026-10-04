import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../id.dart';
import '../shared/shared.dart';

part 'contest_model_link.g.dart';

/// The model a participation flies, snapshotted for the contest.
///
/// Scores refer to this, never to the catalog entry. See
/// `plan/data-model/entities/contest_model_link.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class ContestModelLink extends Equatable implements Synchronizable {
  ContestModelLink({
    required this.id,
    required this.contestId,
    required this.contestParticipationId,
    this.modelCatalogId,
    required String modelName,
    this.manufacturer,
    required String modelId,
    this.contestSpecificIdentifier,
    this.revision = 0,
  }) : modelName = requireNotBlank(modelName, 'modelName'),
       modelId = requireNotBlank(modelId, 'modelId') {
    requireNonNegative(revision, 'revision');
  }

  factory ContestModelLink.fromJson(Map<String, Object?> json) =>
      _$ContestModelLinkFromJson(json);

  @override
  final Id id;
  final Id contestId;
  final Id contestParticipationId;

  /// The catalog entry this was copied from, if any.
  final Id? modelCatalogId;

  final String modelName;
  final String? manufacturer;

  /// External model identifier.
  final String modelId;

  final String? contestSpecificIdentifier;

  @override
  final int revision;

  @override
  String get entityType => 'ContestModelLink';

  @override
  SyncScope get syncScope => SyncScope.contest;

  Map<String, Object?> toJson() => _$ContestModelLinkToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    contestParticipationId,
    modelCatalogId,
    modelName,
    manufacturer,
    modelId,
    contestSpecificIdentifier,
    revision,
  ];
}
