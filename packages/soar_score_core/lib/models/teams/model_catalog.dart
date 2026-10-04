import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../id.dart';
import '../shared/shared.dart';

part 'model_catalog.g.dart';

/// A director's own reusable model name and manufacturer.
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
    required String name,
    this.manufacturer,
    this.revision = 0,
  }) : name = requireNotBlank(name, 'name') {
    requireNonNegative(revision, 'revision');
  }

  factory ModelCatalog.fromJson(Map<String, Object?> json) =>
      _$ModelCatalogFromJson(json);

  @override
  final Id id;

  /// The director who owns and maintains this entry.
  final Id ownerAccountId;

  final String name;
  final String? manufacturer;

  @override
  final int revision;

  @override
  String get entityType => 'ModelCatalog';

  @override
  SyncScope get syncScope => SyncScope.director;

  Map<String, Object?> toJson() => _$ModelCatalogToJson(this);

  @override
  List<Object?> get props => [id, ownerAccountId, name, manufacturer, revision];
}
