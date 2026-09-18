/// Represents a mutation for synchronization.
///
/// Mutations track all changes to entities with base revision, client mutation
/// ID, and timestamps. They enable idempotent synchronization.
class Mutation {
  final String id;
  final String entityId;
  final String baseRevision;
  final String clientMutationId;
  final String? actor;
  final String? authority;
  final String? sourceInstallation;
  final DateTime clientTime;
  final DateTime? serverAcceptanceTime;

  Mutation({
    required this.id,
    required this.entityId,
    required this.baseRevision,
    required this.clientMutationId,
    this.actor,
    this.authority,
    this.sourceInstallation,
    required this.clientTime,
    this.serverAcceptanceTime,
  });
}