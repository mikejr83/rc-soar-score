import 'package:soar_score_core/soar_score_core.dart' as core;

import '../database.dart';
import 'entity_stores.dart';

/// Applies changes the service already accepted.
///
/// Keeps the service's revision, writes no `MutationRecord` or `Tombstone`,
/// and refuses derived entity types, which are recomputed locally.
class DriftReplicatedChangeApplier implements core.ReplicatedChangeApplier {
  DriftReplicatedChangeApplier(this._db, this._stores);

  /// Entity types the calculator writes; they never arrive by replication.
  static const derivedEntityTypes = {
    'FlightResult',
    'ParticipationStanding',
    'TeamStanding',
  };

  final SoarScoreDatabase _db;
  final EntityStores _stores;

  @override
  Future<void> apply(core.ReplicatedChange change) async {
    if (derivedEntityTypes.contains(change.entityType)) {
      throw ArgumentError.value(
        change.entityType,
        'change.entityType',
        'is derived data and is recomputed, never replicated',
      );
    }
    final store = _stores.of(change.entityType);
    await _db.transaction(() async {
      final stored = await store.findJson(change.entityId);
      if (change.isDelete) {
        if (stored == null) return;
        if (change.entityType == 'LandingTable') {
          // The entries go with their table.
          await _stores
              .of('LandingResult')
              .removeWhereId('landing_table_id', change.entityId);
        }
        await store.remove(change.entityId);
        return;
      }
      final storedRevision = stored?['revision'] as int?;
      if (store.hasRevision &&
          storedRevision != null &&
          storedRevision >= change.revision) {
        return;
      }
      final json = {...change.payload};
      if (store.hasRevision) json['revision'] = change.revision;
      await store.upsertJson(store.encode(store.decode(json)));
      if (change.entityType == 'LandingTable') {
        // A landing table travels with its entries in one change.
        final results = _stores.of('LandingResult');
        for (final entry in json['results'] as List<Object?>? ?? const []) {
          final result = results.decode(entry! as Map<String, Object?>);
          await results.upsertJson(results.encode(result));
        }
      }
    });
  }
}
