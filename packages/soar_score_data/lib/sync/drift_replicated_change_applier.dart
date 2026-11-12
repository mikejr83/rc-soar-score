import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:soar_score_core/soar_score_core.dart' as core;

import '../database.dart';
import 'assignment_markers.dart';
import 'current_attempt_pointer.dart';
import 'entity_stores.dart';
import 'sql_placeholders.dart';

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
  Future<bool> apply(core.ReplicatedChange change) async {
    if (derivedEntityTypes.contains(change.entityType)) {
      throw core.UnsupportedEntityTypeError(
        change.entityType,
        'is derived data and is recomputed, never replicated',
      );
    }
    final store = _stores.of(change.entityType);
    return _db.transaction<bool>(() async {
      final stored = await store.findJson(change.entityId);
      if (change.isDelete) {
        if (stored == null) return false;
        if (change.entityType == 'LandingTable') {
          // The entries go with their table.
          await _stores
              .of('LandingResult')
              .removeWhereId('landing_table_id', change.entityId);
        }
        await store.remove(change.entityId);
        if (change.entityType == 'ParticipantProfile') {
          // A deleted participant keeps no link: the pilot is linked again at
          // the next import.
          await _stores
              .of('PilotImportLink')
              .removeWhereId('participant_profile_id', change.entityId);
        }
        if (change.entityType == 'MatrixAssignment') {
          await clearSupersededMarkers(_db, change.entityId);
        }
        return true;
      }
      final storedRevision = stored?['revision'] as int?;
      if (store.hasRevision &&
          storedRevision != null &&
          storedRevision >= change.revision) {
        return false;
      }
      final json = {...change.payload}..remove('supersedes');
      if (store.hasRevision) json['revision'] = change.revision;
      if (change.entityType == 'PilotImportLink' && stored == null) {
        final incoming = core.PilotImportLink.fromJson(json);
        final links = await _stores
            .of('PilotImportLink')
            .whereId('owner_account_id', incoming.ownerAccountId);
        for (final row in links) {
          final local = row as core.PilotImportLink;
          if (local.sourceSystem != incoming.sourceSystem ||
              local.sourcePilotNo != incoming.sourcePilotNo ||
              local.id == incoming.id)
            continue;
          // The service holds another link for this pilot. This installation's
          // own link leaves the unique index so the service's can come in; its
          // mutations stay in the outbox (or already sit in the service's
          // conflict), which keeps the director's choice for the review.
          await store.remove(local.id);
        }
      }
      final supersedes = change.payload['supersedes'];
      // A store with revisions only gets here for a newer one, which is a
      // change. Without revisions an identical payload (a replayed page) is
      // written again and must be told apart by what the rows hold.
      var changed = store.hasRevision;
      if (change.entityType == 'MatrixAssignment' && supersedes is String) {
        // A move marks the old row first, so it leaves the unique index on
        // live assignments before the new row enters it.
        final marked = await _db.customUpdate(
          portableSql(
            _db,
            'UPDATE matrix_assignments SET superseded_by_assignment_id = ? '
            'WHERE id = ? AND superseded_by_assignment_id IS NULL',
          ),
          variables: [
            Variable<String>(change.entityId.value),
            Variable<String>(supersedes),
          ],
          updates: {_db.matrixAssignments},
        );
        if (marked > 0) changed = true;
      }
      await store.upsertJson(store.encode(store.decode(json)));
      if (!changed && !_same(stored, await store.findJson(change.entityId))) {
        changed = true;
      }
      if (change.entityType == 'LandingTable') {
        // A landing table travels with its entries in one change.
        final results = _stores.of('LandingResult');
        for (final entry in json['results'] as List<Object?>? ?? const []) {
          final result = results.decode(entry! as Map<String, Object?>);
          final id = core.Id.parse(
            (entry as Map<String, Object?>)['id']! as String,
          );
          final before = await results.findJson(id);
          await results.upsertJson(results.encode(result));
          if (!_same(before, await results.findJson(id))) changed = true;
        }
      }
      await _reconcileCurrentAttempt(change.entityType, json);
      return changed;
    });
  }

  /// Fills the slot pointer for scores that arrive without one: changes
  /// written before the pointer existed carry none, and the rows they depend
  /// on may come in separate batches. A slot whose placeholder already holds a
  /// pointer, or has no score yet, is left alone, so newer snapshots win.
  Future<void> _reconcileCurrentAttempt(
    String entityType,
    Map<String, Object?> json,
  ) async {
    final placeholderId = switch (entityType) {
      'ScorePlaceholder' => json['id'],
      'ScoreAttempt' || 'OfficialScore' => json['score_placeholder_id'],
      _ => null,
    };
    if (placeholderId is! String) return;
    await fillCurrentAttemptIds(_db, placeholderId: placeholderId);
  }

  /// Whether two stored rows hold the same values.
  static bool _same(Map<String, Object?>? a, Map<String, Object?>? b) =>
      a == null || b == null ? a == b : jsonEncode(a) == jsonEncode(b);
}
