import '../../enums/authority.dart';
import '../../models/id.dart';

/// One unsent mutation of an exchange, as the service receives it.
class SyncMutation {
  const SyncMutation({
    required this.id,
    required this.clientMutationId,
    required this.entityType,
    required this.entityId,
    required this.authority,
    required this.clientTime,
    required this.payload,
    this.baseRevision,
    this.dependsOnMutationId,
  });

  final Id id;
  final String clientMutationId;
  final String entityType;
  final Id entityId;
  final int? baseRevision;
  final Authority authority;
  final DateTime clientTime;
  final Id? dependsOnMutationId;

  /// A `VersionedPayload` as JSON.
  final Map<String, Object?> payload;
}
