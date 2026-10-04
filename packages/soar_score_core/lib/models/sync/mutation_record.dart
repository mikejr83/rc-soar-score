import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../enums/authority.dart';
import '../../enums/mutation_outcome.dart';
import '../id.dart';
import '../shared/shared.dart';

part 'mutation_record.g.dart';

/// One client mutation request and the service's response to it.
///
/// Append-only: the service sets the outcome and times once. It carries a
/// revision only through [baseRevision]. See
/// `plan/data-model/entities/mutation_record.md`.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: true)
@IdConverter()
@UtcTimestampConverter()
class MutationRecord extends Equatable implements SyncScoped {
  MutationRecord({
    required this.id,
    this.contestId,
    this.ownerAccountId,
    this.sequence,
    required String entityType,
    required this.entityId,
    this.baseRevision,
    required String clientMutationId,
    this.actorId,
    required this.authority,
    this.sourceInstallationId,
    this.sourceDevice,
    required this.clientTime,
    this.serverAcceptanceTime,
    this.serverRejectionTime,
    required Map<String, Object?> payload,
    this.outcome = MutationOutcome.pending,
    this.reasonCode,
    this.errorMessage,
    this.dependsOnMutationId,
  }) : entityType = requireNotBlank(entityType, 'entityType'),
       clientMutationId = requireNotBlank(clientMutationId, 'clientMutationId'),
       payload = Map.unmodifiable(payload) {
    requireExactlyOneScope(
      contestId: contestId,
      ownerAccountId: ownerAccountId,
    );
    if (sequence != null && outcome != MutationOutcome.accepted) {
      throw ArgumentError.value(
        sequence,
        'sequence',
        'is set only on an accepted change',
      );
    }
    if (baseRevision != null) requireNonNegative(baseRevision!, 'baseRevision');
  }

  factory MutationRecord.fromJson(Map<String, Object?> json) =>
      _$MutationRecordFromJson(json);

  final Id id;

  /// Set for a change to contest data; exactly one of this and
  /// [ownerAccountId].
  final Id? contestId;

  /// Set for a change to a director's own data.
  final Id? ownerAccountId;

  /// Position in the scope's sequence, assigned when the change is accepted.
  final int? sequence;

  /// Stable name of the entity type that was changed.
  final String entityType;

  final Id entityId;

  /// Revision the change was based on; null for a creation.
  final int? baseRevision;

  /// Unique request identifier from the client, used for idempotency.
  final String clientMutationId;

  /// The account that made the change; null for a change by the system.
  final Id? actorId;

  final Authority authority;

  /// The installation the change came from; null for a participant submission
  /// or a change made by the service itself.
  final Id? sourceInstallationId;

  /// Opaque identifier of the device, for audit.
  final String? sourceDevice;

  /// Time reported by the client; for audit only, never used to order changes.
  final DateTime clientTime;

  final DateTime? serverAcceptanceTime;
  final DateTime? serverRejectionTime;

  /// The entity state or delta at the time of the change.
  final Map<String, Object?> payload;

  final MutationOutcome outcome;

  /// Machine-readable reason for a rejection, conflict or skip, for example
  /// `stale_base` or `entity_deleted`.
  final String? reasonCode;

  final String? errorMessage;

  /// The mutation this change depends on.
  final Id? dependsOnMutationId;

  @override
  SyncScope get syncScope =>
      contestId != null ? SyncScope.contest : SyncScope.director;

  Map<String, Object?> toJson() => _$MutationRecordToJson(this);

  @override
  List<Object?> get props => [
    id,
    contestId,
    ownerAccountId,
    sequence,
    entityType,
    entityId,
    baseRevision,
    clientMutationId,
    actorId,
    authority,
    sourceInstallationId,
    sourceDevice,
    clientTime,
    serverAcceptanceTime,
    serverRejectionTime,
    payload,
    outcome,
    reasonCode,
    errorMessage,
    dependsOnMutationId,
  ];
}
