import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/conflict_resolution.dart';
import '../../enums/conflict_resolution_choice.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'conflict_record.g.dart';

/// A conflict between two mutations on the same entity. Both versions are
/// preserved.
///
/// See `plan/data-model/entities/conflict_record.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class ConflictRecord extends Equatable implements SyncScoped {
  ConflictRecord({
    required this.id,
    this.contestId,
    this.ownerAccountId,
    required String entityType,
    required this.entityId,
    this.acceptedMutationId,
    required this.competingMutationId,
    required String reasonCode,
    this.reason,
    this.requiresAction = true,
    this.resolution = ConflictResolution.pending,
    this.resolutionChoice,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    Map<String, Object?>? acceptedPayload,
    Map<String, Object?>? competingPayload,
    this.entityRevision,
  }) : acceptedPayload = acceptedPayload == null
           ? null
           : Map.unmodifiable(acceptedPayload),
       competingPayload = competingPayload == null
           ? null
           : Map.unmodifiable(competingPayload),
       entityType = requireNotBlank(entityType, 'entityType'),
       reasonCode = requireNotBlank(reasonCode, 'reasonCode') {
    requireExactlyOneScope(
      contestId: contestId,
      ownerAccountId: ownerAccountId,
    );
    if (!requiresAction && resolution != ConflictResolution.automatic) {
      throw ArgumentError(
        'a silent record (requires_action false) must be resolved Automatic',
      );
    }
    if (resolution == ConflictResolution.pending &&
        (resolutionChoice != null ||
            resolvedAt != null ||
            resolvedBy != null)) {
      throw ArgumentError('a pending conflict cannot carry a resolution');
    }
  }

  factory ConflictRecord.fromJson(Map<String, Object?> json) =>
      _$ConflictRecordFromJson(json);

  final Id id;

  /// Exactly one of this and [ownerAccountId] is set.
  final Id? contestId;
  final Id? ownerAccountId;

  final String entityType;
  final Id entityId;

  /// The change that was applied; null while no change has been applied.
  final Id? acceptedMutationId;

  /// The change that collided with it.
  final Id competingMutationId;

  /// Machine-readable reason, for example `stale_base` or `unique_violation`.
  final String reasonCode;

  final String? reason;

  /// Whether the director has to decide. False for a silent record.
  final bool requiresAction;

  final ConflictResolution resolution;
  final ConflictResolutionChoice? resolutionChoice;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  /// The account that resolved it, for a manual resolution.
  final Id? resolvedBy;

  /// The entity state the service applied; null while no change has been
  /// applied. Kept with the record so the side-by-side view needs no lookup.
  final Map<String, Object?>? acceptedPayload;

  /// The entity state of the colliding mutation, as submitted.
  final Map<String, Object?>? competingPayload;

  /// The entity's revision when the conflict was recorded, so a resolution can
  /// be based on it.
  final int? entityRevision;

  @override
  SyncScope get syncScope =>
      contestId != null ? SyncScope.contest : SyncScope.director;

  Map<String, Object?> toJson() => _$ConflictRecordToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    ownerAccountId,
    entityType,
    entityId,
    acceptedMutationId,
    competingMutationId,
    reasonCode,
    reason,
    requiresAction,
    resolution,
    resolutionChoice,
    createdAt,
    resolvedAt,
    resolvedBy,
    acceptedPayload,
    competingPayload,
    entityRevision,
  ];
}
