import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/tombstone_status.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'tombstone.g.dart';

/// A soft-deletion marker, so a delete survives synchronization.
///
/// Kept for 90 days after the server acknowledges the deletion. See
/// `plan/data-model/entities/tombstone.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class Tombstone extends Equatable implements SyncScoped {
  Tombstone({
    required this.id,
    this.contestId,
    this.ownerAccountId,
    required String entityType,
    required this.entityId,
    this.status = TombstoneStatus.pending,
    required this.deletedAt,
    this.acknowledgedAt,
    this.purgeAfter,
    this.deletionReason,
  }) : entityType = requireNotBlank(entityType, 'entityType') {
    requireExactlyOneScope(
      contestId: contestId,
      ownerAccountId: ownerAccountId,
    );
    if (status == TombstoneStatus.pending &&
        (acknowledgedAt != null || purgeAfter != null)) {
      throw ArgumentError('a pending tombstone has no acknowledgement');
    }
  }

  factory Tombstone.fromJson(Map<String, Object?> json) =>
      _$TombstoneFromJson(json);

  /// How long the service keeps an acknowledged tombstone.
  static const Duration retention = Duration(days: 90);

  final Id id;

  /// Exactly one of this and [ownerAccountId] is set.
  final Id? contestId;
  final Id? ownerAccountId;

  final String entityType;
  final Id entityId;
  final TombstoneStatus status;

  /// When the entity was deleted, as reported by the deleting installation.
  final DateTime deletedAt;

  /// When the server acknowledged the deletion (server time).
  final DateTime? acknowledgedAt;

  /// [acknowledgedAt] plus [retention]; null until acknowledged.
  final DateTime? purgeAfter;

  final String? deletionReason;

  /// A copy marked acknowledged at [at], with the purge date set.
  Tombstone acknowledge(DateTime at) {
    if (status == TombstoneStatus.acknowledged) {
      throw StateError('tombstone $id is already acknowledged');
    }
    return Tombstone(
      id: id,
      contestId: contestId,
      ownerAccountId: ownerAccountId,
      entityType: entityType,
      entityId: entityId,
      status: TombstoneStatus.acknowledged,
      deletedAt: deletedAt,
      acknowledgedAt: at,
      purgeAfter: at.toUtc().add(retention),
      deletionReason: deletionReason,
    );
  }

  @override
  SyncScope get syncScope =>
      contestId != null ? SyncScope.contest : SyncScope.director;

  Map<String, Object?> toJson() => _$TombstoneToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    ownerAccountId,
    entityType,
    entityId,
    status,
    deletedAt,
    acknowledgedAt,
    purgeAfter,
    deletionReason,
  ];
}
