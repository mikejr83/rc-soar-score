import '../models/id.dart';
import '../models/sync/audit_event.dart';
import '../models/sync/conflict_record.dart';
import '../models/sync/installation.dart';
import '../models/sync/installation_activation.dart';
import '../models/sync/mutation_record.dart';
import '../models/sync/sync_cursor.dart';
import '../models/sync/tombstone.dart';
import 'sync_scope_key.dart';

/// Storage the server-side sync acceptor works through.
///
/// Backend only: an installation has no installations, activations or accepted
/// log, so an implementation on an installation's database throws a
/// `BackendOnlyError`. Everything the acceptor decides is domain logic in
/// core; this contract only reads and writes.
abstract interface class SyncAcceptorStore {
  /// Runs [body] atomically: all of its writes commit together or, if [body]
  /// or the commit throws, none do.
  ///
  /// A write that breaks a unique or foreign-key rule surfaces as a
  /// `SyncConstraintError`, whether it fails inside [body] or when the
  /// transaction commits.
  Future<T> transaction<T>(Future<T> Function(SyncAcceptorTransaction tx) body);
}

/// The reads and writes of one acceptor transaction.
abstract interface class SyncAcceptorTransaction {
  Future<Installation?> findInstallation(Id id);

  /// The account's installations, oldest first, revoked ones included.
  Future<List<Installation>> listInstallations(Id ownerAccountId);

  Future<Installation> saveInstallation(Installation installation);

  /// Every activation of [contestId], oldest first.
  Future<List<InstallationActivation>> listActivations(Id contestId);

  Future<InstallationActivation> saveActivation(
    InstallationActivation activation,
  );

  Future<SyncCursor?> findCursor(Id installationId, SyncScopeKey scope);

  Future<SyncCursor> saveCursor(SyncCursor cursor);

  /// The stored entity as JSON, or null. [entityType] is a syncable type.
  Future<Map<String, Object?>?> findEntity(String entityType, Id id);

  /// The stored entities of [entityType] whose [field] equals [value].
  Future<List<Map<String, Object?>>> findEntitiesWhere(
    String entityType,
    String field,
    Id value,
  );

  /// Inserts or replaces the entity.
  ///
  /// Throws a `SyncPayloadError` when [json] is not a valid [entityType] and a
  /// `SyncConstraintError` when the write breaks a database rule. A failed
  /// write leaves the rest of the transaction usable.
  Future<void> writeEntity(String entityType, Map<String, Object?> json);

  /// Deletes the entity; a landing table takes its entries with it.
  Future<void> removeEntity(String entityType, Id id);

  /// Marks the assignment [sourceId] of [contestId] as moved by [movedId].
  /// An assignment of another contest is never marked.
  Future<void> markSuperseded(Id sourceId, Id movedId, Id contestId);

  /// The decided mutation with [clientMutationId] in [scope], or null.
  Future<MutationRecord?> findMutation(
    SyncScopeKey scope,
    String clientMutationId,
  );

  /// The accepted mutations that changed one entity, oldest sequence first.
  Future<List<MutationRecord>> acceptedMutationsFor(
    SyncScopeKey scope,
    String entityType,
    Id entityId,
  );

  /// The scope's highest assigned sequence; 0 before any change.
  Future<int> highestSequence(SyncScopeKey scope);

  /// Stores a decided mutation. An accepted one carries its sequence.
  Future<void> recordMutation(MutationRecord record);

  /// Accepted mutations of [scope] with a sequence above [afterSequence],
  /// in sequence order, at most [limit].
  Future<List<MutationRecord>> acceptedAfter(
    SyncScopeKey scope,
    int afterSequence, {
    required int limit,
  });

  Future<Tombstone?> findTombstone(String entityType, Id entityId);

  Future<void> saveTombstone(Tombstone tombstone);

  Future<ConflictRecord?> findConflict(Id id);

  Future<void> saveConflict(ConflictRecord conflict);

  /// Conflicts of [scope] the director still has to decide.
  Future<List<ConflictRecord>> conflictsNeedingAction(SyncScopeKey scope);

  Future<void> appendAudit(AuditEvent event);
}
