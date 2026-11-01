import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../id.dart';
import '../shared/shared.dart';

part 'model_catalog.g.dart';

/// A model that belongs to a participant profile, reusable across the
/// director's contests.
///
/// Private to the owning director.
///
/// See `plan/data-model/entities/model_catalog.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class ModelCatalog extends Equatable implements Synchronizable {
  ModelCatalog({
    required this.id,
    required this.ownerAccountId,
    required this.participantProfileId,
    required String name,
    this.manufacturer,
    String? modelId,
    this.revision = 0,
  }) : name = requireNotBlank(name, 'name'),
       modelId = modelId == null ? null : requireNotBlank(modelId, 'modelId') {
    requireNonNegative(revision, 'revision');
  }

  factory ModelCatalog.fromJson(Map<String, Object?> json) =>
      _$ModelCatalogFromJson(json);

  @override
  final Id id;

  /// The director who owns and maintains this entry.
  final Id ownerAccountId;

  /// The person who flies this model.
  final Id participantProfileId;

  final String name;
  final String? manufacturer;

  /// The identifier the pilot applied to the model, if any.
  final String? modelId;

  @override
  final int revision;

  @override
  String get entityType => 'ModelCatalog';

  @override
  SyncScope get syncScope => SyncScope.director;

  Map<String, Object?> toJson() => _$ModelCatalogToJson(this);

  @override
  List<Object?> get props => [
    id,
    ownerAccountId,
    participantProfileId,
    name,
    manufacturer,
    modelId,
    revision,
  ];
}
